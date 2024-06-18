#!sh

# Sources:
# - https://superuser.com/questions/621870/test-if-a-port-on-a-remote-system-is-reachable-without-telnet

# TCP

nc -vz  -w '3' 'localhost' '80'
nc -nvz -w '3' '127.0.0.1' '80'

nc 'localhost' '22' -e true  # busybox's nc

timeout '3' cat < '/dev/tcp/localhost/80'
timeout '3' cat < '/dev/tcp/127.0.0.1/80'

curl -fsS -o '/dev/null' -w "%{http_code}" --connect-timeout '3' 'http://www.example.org/'
curl -fksS -o '/dev/null' -w "%{http_code}" --connect-timeout '3' 'https://www.example.org/'


# UDP

nc -uvz  -w '3' 'localhost' '25'
nc -nuvz -w '3' '127.0.0.1' '25'

timeout '3' cat < '/dev/udp/localhost/80'
timeout '3' cat < '/dev/udp/127.0.0.1/25'
