# Extract attachments from multipart emails

When saved as plain text, emails may be saved as S/MIME files with attachments.  
In such cases the text file itself contains the multipart message body of the email, so the attachments are provided as base64 streams:

```text
 1 --------------060903090608060502040600
 2 Content-Type: application/x-gzip;
 3  name="myawesomefile.tar.gz"
 4 Content-Transfer-Encoding: base64
 5 Content-Disposition: attachment;
 6  filename="myawesomefile.tar.gz"
 7
 8 qrsIAstukk4AA+17Wa+jSpZuPfMrrK6Hvi1qJ4OxsfuodQU2YLDBUJDGrvqBeR7MaPj1N7D3
 9 OEmSxO8Wq7+3Y48dTWvXi8XvvKj8od6vPf9vKjWIv1v7nt3G/d8rEX5D/FdrDIxj2IrUPeE/
10 j5Dv4g9+fPnTRcX006T++LdYYw7w+i...
```

You can use `munpack` to easily extract attachments out of such text files and write them into a proper named files.

```sh
$ munpack -f plaintext.eml
myawesomefile.tar.gz (application/x-gzip)
```

## Sources

- [Extract attachments from multipart messages]

[extract attachments from multipart messages]: https://liquidat.wordpress.com/2013/08/07/short-tip-extract-attachments-from-multipart-messages/
