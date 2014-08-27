
CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

CPPFLAGS=$(CCOPTS) -I../glfw3/include -I../openal/include -I../stb -I../tinycthread \
-D__STRICT_ANSI__
#-DUSE_THREADED_DELAY

LD=g++
LDFLAGS=-Wl,--subsystem,windows -L../openal/libs/Win32 -L../glfw3/lib/Win32
LDLIBS=-lglew32 -lglfw3 -lopengl32 -lglu32 -lgdi32 -lws2_32 -lOpenAL32

OBJS=../stb/stb_image.o ../stb/stb_vorbis.o ../tinycthread/tinycthread.o ../main.o

all : $(OUT)

$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)
	