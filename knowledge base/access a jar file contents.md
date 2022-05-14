# Access a jar file's contents

A `.jar` file is nothing more than an archive.  
You can find all the files it contains just unzipping it:

```sh
$ unzip file.jar
Archive:  file.jar
   creating: META-INF/
  inflating: META-INF/MANIFEST.MF
   creating: org/
  …
  inflating: META-INF/maven/org.apache.hive/hive-contrib/pom.properties
```
