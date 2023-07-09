# Date

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)

## TL;DR

```sh
# Print the current date in the 'YYYY-MM-DD' format.
date '+%F'
date '+%Y-%m-%d'

# Print the current date in the 'YYYY-MM-DDThh:mm:SS' format.
date '+%FT%T'
date '+%Y-%m-%dT%H:%M:%S'

# Print a specific date in a different format.
date -d '+10 days' '+%FT%T.00Z'  # GNU
date -v '+10d' '+%FT%T.00Z'      # BSD
```
