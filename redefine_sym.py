import sys; print(' '.join('-D{func}={prefix}_{func}'.format(func = func, prefix = sys.argv[1]) for func in sys.argv[2:]))
