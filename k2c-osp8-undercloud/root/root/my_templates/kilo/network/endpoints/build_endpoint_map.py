#!/usr/bin/env python

"""
Generate the endpoint_map.yaml template from data in the endpoint_data.yaml
file.

By default the files in the same directory as this script are operated on, but
different files can be optionally specified on the command line.

The --check option verifies that the current output file is up-to-date with the
latest data in the input file. The script exits with status code 2 if a
mismatch is detected.
"""

from __future__ import print_function


__all__ = ['load_endpoint_data', 'generate_endpoint_map_template',
           'write_template', 'build_endpoint_map', 'check_up_to_date']


import copy
import os
import sys
import yaml


(IN_FILE, OUT_FILE) = ('endpoint_data.yaml', 'endpoint_map.yaml')

SUBST = (SUBST_IP_ADDRESS, SUBST_CLOUDNAME) = ('IP_ADDRESS', 'CLOUDNAME')
PARAMS = (PARAM_CLOUDNAME, PARAM_ENDPOINTMAP) = ('CloudName', 'EndpointMap')
FIELDS = (F_PORT, F_PROTOCOL, F_HOST) = ('port', 'protocol', 'host')

ENDPOINT_TYPES = frozenset(['Internal', 'Public', 'Admin'])


def get_file(default_fn, override=None, writable=False):
    if override == '-':
        if writable:
            return sys.stdout
        else:
            return sys.stdin

    if override is not None:
        filename = override
    else:
        filename = os.path.join(os.path.dirname(__file__), default_fn)

    return open(filename, 'w' if writable else 'r')


def load_endpoint_data(infile=None):
    with get_file(IN_FILE, infile) as f:
        return yaml.safe_load(f)


def vip_param_name(endpoint_type_defn):
    return endpoint_type_defn['vip_param'] + 'VirtualIP'


def vip_param_names(config):
    def ep_types(svc):
        return (v for k, v in svc.items() if k in ENDPOINT_TYPES or not k)

    return set(vip_param_name(defn) for svc in config.values()
                                    for defn in ep_types(svc))


def endpoint_map_default(config):
    def map_item(ep_name, ep_type, svc):
        values = {
            F_PROTOCOL: svc.get(F_PROTOCOL, 'http'),
            F_PORT: str(svc[ep_type].get(F_PORT, svc[F_PORT])),
            F_HOST: SUBST_IP_ADDRESS,
        }
        return ep_name + ep_type, values

    return dict(map_item(ep_name,
                         ep_type,
                         svc) for ep_name, svc in config.items()
                              for ep_type in set(svc) & ENDPOINT_TYPES)


def template_parameters(config):
    vip_param = {'type': 'string', 'default': ''}
    params = dict((n, vip_param.copy()) for n in vip_param_names(config))

    params[PARAM_ENDPOINTMAP] = {
        'type': 'json',
        'default': endpoint_map_default(config),
        'description': 'Mapping of service endpoint -> protocol. '
                       'Typically set via parameter_defaults in the '
                       'resource registry.'
    }
    params[PARAM_CLOUDNAME] = {
        'type': 'string',
        'default': '',
        'description': 'The DNS name of this cloud. '
                       'e.g. ci-overcloud.tripleo.org'
    }
    return params


def template_output_definition(endpoint_name,
                               endpoint_variant,
                               endpoint_type,
                               vip_param,
                               uri_suffix=None,
                               name_override=None):
    def extract_field(field):
        assert field in FIELDS
        return {'get_param': ['EndpointMap',
                              endpoint_name + endpoint_type,
                              copy.copy(field)]}

    port = extract_field(F_PORT)
    protocol = extract_field(F_PROTOCOL)
    host = {
        'str_replace': {
            'template': extract_field(F_HOST),
            'params': {
                SUBST_IP_ADDRESS: {'get_param': vip_param},
                SUBST_CLOUDNAME: {'get_param': PARAM_CLOUDNAME},
            }
        }
    }
    uri_fields = [protocol, '://', copy.deepcopy(host), ':', port]
    uri_fields_suffix = (copy.deepcopy(uri_fields) +
                         ([uri_suffix] if uri_suffix is not None else []))

    name = name_override if name_override is not None else (endpoint_name +
                                                            endpoint_variant +
                                                            endpoint_type)

    return name, {
        'port': extract_field('port'),
        'protocol': extract_field('protocol'),
        'host': host,
        'uri': {
            'list_join': ['', uri_fields_suffix]
        },
        'uri_no_suffix': {
            'list_join': ['', uri_fields]
        },
    }


def template_endpoint_items(config):
    for ep_name, svc in config.items():
        for ep_type in set(svc) & ENDPOINT_TYPES:
            defn = svc[ep_type]
            for variant, suffix in defn.get('uri_suffixes',
                                            {'': None}).items():
                name_override = defn.get('names', {}).get(variant)
                yield template_output_definition(ep_name, variant, ep_type,
                                                 vip_param_name(defn),
                                                 suffix,
                                                 name_override)


def generate_endpoint_map_template(config):
    return {
        'heat_template_version': '2015-04-30',
        'description': 'A map of OpenStack endpoints. Since the endpoints are '
                       'URLs, we need to have brackets around IPv6 addresses. '
                       'The inputs to these parameters come from '
                       'net_ip_uri_map, which will include these brackets in '
                       'IPv6 addresses.',
        'parameters': template_parameters(config),
        'outputs': {
            'endpoint_map': {
                'value': dict(template_endpoint_items(config))
            }
        },
    }


autogen_warning = """### DO NOT MODIFY THIS FILE
### This file is automatically generated from endpoint_data.yaml
### by the script build_endpoint_map.py

"""


def write_template(template, filename=None):
    with get_file(OUT_FILE, filename, writable=True) as f:
        f.write(autogen_warning)
        yaml.safe_dump(template, f, width=68)


def read_template(template, filename=None):
    with get_file(OUT_FILE, filename) as f:
        return yaml.safe_load(f)


def build_endpoint_map(output_filename=None, input_filename=None):
    if output_filename is not None and output_filename == input_filename:
        raise Exception('Cannot read from and write to the same file')
    config = load_endpoint_data(input_filename)
    template = generate_endpoint_map_template(config)
    write_template(template, output_filename)


def check_up_to_date(output_filename=None, input_filename=None):
    if output_filename is not None and output_filename == input_filename:
        raise Exception('Input and output filenames must be different')
    config = load_endpoint_data(input_filename)
    template = generate_endpoint_map_template(config)
    existing_template = read_template(output_filename)
    return existing_template == template


def get_options():
    from optparse import OptionParser

    parser = OptionParser('usage: %prog'
                          ' [-i INPUT_FILE] [-o OUTPUT_FILE] [--check]',
                          description=__doc__)
    parser.add_option('-i', '--input', dest='input_file', action='store',
                      default=None,
                      help='Specify a different endpoint data file')
    parser.add_option('-o', '--output', dest='output_file', action='store',
                      default=None,
                      help='Specify a different endpoint map template file')
    parser.add_option('-c', '--check', dest='check', action='store_true',
                      default=False, help='Check that the output file is '
                                          'up to date with the data')
    parser.add_option('-d', '--debug', dest='debug', action='store_true',
                      default=False, help='Print stack traces on error')

    return parser.parse_args()


def main():
    options, args = get_options()
    if args:
        print('Warning: ignoring positional args: %s' % ' '.join(args),
              file=sys.stderr)

    try:
        if options.check:
            if not check_up_to_date(options.output_file, options.input_file):
                print('EndpointMap template does not match input data',
                      file=sys.stderr)
                sys.exit(2)
        else:
            build_endpoint_map(options.output_file, options.input_file)
    except Exception as exc:
        if options.debug:
            raise
        print('%s: %s' % (type(exc).__name__, str(exc)), file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
