import unittest
import allosmod
import saliweb.test
import saliweb.backend
import os


class Tests(saliweb.test.TestCase):
    """Check JobCounter class"""

    def test_get(self):
        """Test JobCounter.get method"""
        jc = allosmod.JobCounter()
        with open('jobcounter', 'w') as fh:
            fh.write('42\n')
        self.assertEqual(jc.get(), 42)
        os.unlink('jobcounter')

    def test_set(self):
        """Test JobCounter.set method"""
        jc = allosmod.JobCounter()
        jc.set(99)
        with open('jobcounter') as fh:
            contents = fh.read()
        self.assertEqual(contents, '99\n')
        os.unlink('jobcounter')


if __name__ == '__main__':
    unittest.main()
