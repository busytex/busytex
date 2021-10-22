import os
import sys

print('BEGIN {')
print('my %modules = (')
for p in sys.argv[1:]:
    path, *key = p.split('@')
    if not key:
        key = [os.path.basename(path)]
    print(f'''"${key[0]}" => <<'__EOI__',''')
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
