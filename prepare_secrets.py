#!/usr/bin/env python3
from subprocess import Popen, PIPE
import yaml
import re


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
            print('Error something')
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


def main():
    lp = LPass()
    if not lp.logged_in:
        print("Not logged into lastpass: please run 'lpass login' first")
        exit(1)
    with open('hass_config/secrets.yaml', 'w') as w:
        with open("hass_config/secrets_template_local.yaml", 'r') as stream:
            data_loaded = yaml.load(stream)
            for key in data_loaded:
                print(key)
                secret = data_loaded[key]
                m = re.search('{{ lookup\(\'lastpass1\', \'(.+?)\', field=\'(.+?)\'',
                              data_loaded[key])
                if m:
                    secret = lp.get_field(m.group(1), m.group(2)).replace('\n', '')
                yaml.safe_dump({key: secret}, w, default_style='\"')


if __name__ == "__main__":
    main()
