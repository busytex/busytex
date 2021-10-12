import sys

print(sys.argv, file = sys.stderr)

print('BEGIN {')
print('my %modules = (')
for path in sys.argv[1:]:
    print(f'''"${path}" => <<' '__EOI__',''')
    print(open(path).read())
    print('1;')
    print('__EOI__')
print(');')
print('unshift @INC, sub {')
print('my $module = $modules{$_[1]}')
print('or return;')
print('return \\$module')
print('};')
print('}')
