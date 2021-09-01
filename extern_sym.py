import sys; open(sys.argv[1], 'w').write(''.join('#define {func} extern {func}\n'.format(func = func) for func in sys.argv[2:]))
