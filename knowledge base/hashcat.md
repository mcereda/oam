# Hashcat

## TL;DR

```sh
# Install it.
sudo zypper install hashcat

# Add your user to the 'video' group to be able to use the GPU.
sudo usermod -a -G 'video' 'username'
sudo gpasswd -a 'username' 'video'

# hashcat [options]... hash|hashfile|hccapxfile [dictionary|mask|directory]...

# Run a benchmark.
hashcat -b

# Run a benchmark on all hash modes.
hashcat -b --benchmark-all

# Show the expected speed for a particular hash mode.
hashcat \
  -m 1800 -a3 -O -w4 --speed-only \
  $(mkpasswd -m sha512crypt '1029384756') \
  ?a?a?a?a?a?a?a?a

# Try to brute-force (-a3) a `sha512crypt`ed (-m1800) string.
# Only test 10-digits strings (--increment --increment-min 10
# --increment-max 10 ?d?d?d?d?d?d?d?d?d?d).
# Use all the available resources possible (-w4), including optimized kernel
# code (-O).
hashcat \
  -m 1800 -a3 -O -w4 --increment --increment-min 10 --increment-max 10 \
  $(mkpasswd -m sha512crypt '1029384756') \
  ?d?d?d?d?d?d?d?d?d?d
```
