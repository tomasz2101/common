#!/usr/bin/env python3
from subprocess import Popen, PIPE
import yaml
import re
import argparse
import logging
import sys
import helpers


class LPass(object):

    def __init__(self, path='lpass'):
        self._cli_path = path

    @property
    def cli_path(self):
        return self._cli_path

    @property
    def logged_in(self):
        out, err = self._run(self._build_args("logout"), stdin="n\n", expected_rc=1)
        return err.startswith("Are you sure you would like to log out?")

    @staticmethod
    def to_bytes(text):
        if text:
            return text.encode('utf-8')

    @staticmethod
    def to_text(text):
        return text.decode()

    def _run(self, args, stdin=None, expected_rc=0):
        p = Popen([self.to_bytes(self.cli_path)] + [self.to_bytes(a) for a in args], stdout=PIPE,
                  stderr=PIPE, stdin=PIPE)
        out, err = p.communicate(self.to_bytes(stdin))
        rc = p.wait()
        if rc != expected_rc:
            logging.error(err)
        return self.to_text(out), self.to_text(err)

    def _build_args(self, command, args=None):
        if args is None:
            args = []
        args = [command] + args
        args += ["--color=never"]
        return args

    def get_field(self, key, field):
        if field in ['username', 'password', 'url', 'notes', 'id', 'name']:
            out, err = self._run(self._build_args("show", ["--{0}".format(field), key]))
        else:
            out, err = self._run(self._build_args("show", ["--field={0}".format(field), key]))
        return out


def parse_args(args):
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--loglevel', '-l', default="WARNING",
                        help='controls verbosity - DEBUG/INFO/(WARNING)/ERROR/CRITICAL')
    parser.add_argument('--input_file', '-if', required=True)
    parser.add_argument('--output_file', '-of', required=True, action='append', nargs='+')
    return parser.parse_args(args)


def main(*args):
    args = parse_args(args)
    helpers.set_loglevel(args.loglevel)
    lp = LPass()
    if not lp.logged_in:
        logging.error("Not logged into lastpass: please run 'lpass login' first")
        exit(1)

    output_lines = []
    with open(args.input_file, 'r') as stream:
        content = stream.readlines()
        for line in content:
            line = line.replace('\n', '')
            m = re.search('{{ lookup\(\'lastpass1\', \'(.+?)\', field=\'(.+?)\'\) }}', line)
            if m:
                logging.info('Getting {name} -> {key}'.format(name=m.group(1), key=m.group(2)))
                secret = lp.get_field(m.group(1), m.group(2))
                line = line.replace(m.group(0), secret).replace('\n', '')

            output_lines.append(line)
    for output_file in args.output_file:
        with open(output_file[0], 'w') as w:
            for line in output_lines:
                w.write(line + '\r\n')


if __name__ == "__main__":
    main(*(sys.argv[1:]))
