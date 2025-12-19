Для оновлення Libgit бібліотеки:

1) збілдати статичні бібліотеки Libgit

2) об'єднуємо лібив один файл
```
libtool -static -o libclibgit2_combined.a \
    libgit2.a \
    libssh2.a \
    libssl.a \
    libcrypto.a
```

2) створити xcframework
```
xcodebuild -create-xcframework \
  -library libclibgit2_combined.a \
  -headers include \
  -output Clibgit2.xcframework
```

3) Створюємо в ньому файл в папці хеадерс: "module.modulemap" з контентом:
```
module Clibgit2 {
    umbrella header "git2.h"
    export *
    link "git2"
}
```

Варіант ``` umbrella "." ``` не підходить бо буде конфліктувати з SetApp бібліотекою
