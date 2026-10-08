mkdir build
clang -target arm64-apple-macosx14.0.0 \
  -fobjc-arc -O2 \
  -c audio.m -o build/audio.o

clang -target arm64-apple-macosx14.0.0 \
  -fobjc-arc -O2 \
  -c menu.m -o build/menu.o

ar rcs libnative.a build/audio.o build/menu.o