# -*- coding: utf-8 -*-
import os
import sys
import unittest
import pprint

this_dir = os.path.dirname(__file__)
sys.path.append(os.path.dirname(this_dir))
import hotstrings_io


class Test(unittest.TestCase):
    def testName(self):
        """test back and forth conversion"""
        test_file = os.path.join(this_dir, 'teststrings.ahk')
        hs_dict = hotstrings_io.file_to_dict(test_file)
        print(pprint.pformat(hs_dict))


        hs_code = hotstrings_io.dict_to_ahkcode(hs_dict)
        print('hs_code:\n%s' % hs_code)


if __name__ == "__main__":
    unittest.main()
