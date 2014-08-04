
CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

CPPFLAGS=$(CCOPTS) -I../glfw3/include -I../openal/include -I../stb -I../tinycthread \
-D__STRICT_ANSI__

LD=g++
LDFLAGS=-Wl,--subsystem,windows -L../openal/libs/Win64 -L../glfw3/lib/Win64/Release
LDLIBS=-lglew32 -lglfw3 -lopengl32 -lglu32 -lgdi32 -lws2_32 -lOpenAL32

OBJS=../stb/stb_image.o ../stb/stb_vorbis.o ../tinycthread/tinycthread.o ../main.o

all : $(OUT)

$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)
	