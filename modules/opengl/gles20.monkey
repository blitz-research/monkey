
#If TARGET<>"glfw" And TARGET<>"android" And TARGET<>"ios" And TARGET<>"html5"
#Error "The opengl.gles20 module is not avaiable for the ${TARGET} target."
#Endif

#OPENGL_GLES20_ENABLED=True
#OPENGL_DEPTH_BUFFER_ENABLED=True

Import monkeytarget

Import brl.databuffer

#If TARGET="glfw"
#If HOST="winnt"
#OPENGL_INIT_EXTENSIONS=True
Import "native/gles20_win32_exts.cpp"
#Endif
Import "native/gles20.glfw.cpp"
#ElseIf TARGET="android"
Import "native/gles20.android.java"
#ElseIf TARGET="ios"
Import "native/gles20.ios.cpp"
#ElseIf TARGET="html5"
Import "native/gles20.html5.js"
#Endif

'${CONST_DECLS}
Const GL_DEPTH_BUFFER_BIT               =$00000100
Const GL_STENCIL_BUFFER_BIT             =$00000400
Const GL_COLOR_BUFFER_BIT               =$00004000
Const GL_FALSE                          =0
Const GL_TRUE                           =1
Const GL_POINTS                         =$0000
Const GL_LINES                          =$0001
Const GL_LINE_LOOP                      =$0002
Const GL_LINE_STRIP                     =$0003
Const GL_TRIANGLES                      =$0004
Const GL_TRIANGLE_STRIP                 =$0005
Const GL_TRIANGLE_FAN                   =$0006
Const GL_ZERO                           =0
Const GL_ONE                            =1
Const GL_SRC_COLOR                      =$0300
Const GL_ONE_MINUS_SRC_COLOR            =$0301
Const GL_SRC_ALPHA                      =$0302
Const GL_ONE_MINUS_SRC_ALPHA            =$0303
Const GL_DST_ALPHA                      =$0304
Const GL_ONE_MINUS_DST_ALPHA            =$0305
Const GL_DST_COLOR                      =$0306
Const GL_ONE_MINUS_DST_COLOR            =$0307
Const GL_SRC_ALPHA_SATURATE             =$0308
Const GL_FUNC_ADD                       =$8006
Const GL_BLEND_EQUATION                 =$8009
Const GL_BLEND_EQUATION_RGB             =$8009
Const GL_BLEND_EQUATION_ALPHA           =$883D
Const GL_FUNC_SUBTRACT                  =$800A
Const GL_FUNC_REVERSE_SUBTRACT          =$800B
Const GL_BLEND_DST_RGB                  =$80C8
Const GL_BLEND_SRC_RGB                  =$80C9
Const GL_BLEND_DST_ALPHA                =$80CA
Const GL_BLEND_SRC_ALPHA                =$80CB
Const GL_CONSTANT_COLOR                 =$8001
Const GL_ONE_MINUS_CONSTANT_COLOR       =$8002
Const GL_CONSTANT_ALPHA                 =$8003
Const GL_ONE_MINUS_CONSTANT_ALPHA       =$8004
Const GL_BLEND_COLOR                    =$8005
Const GL_ARRAY_BUFFER                   =$8892
Const GL_ELEMENT_ARRAY_BUFFER           =$8893
Const GL_ARRAY_BUFFER_BINDING           =$8894
Const GL_ELEMENT_ARRAY_BUFFER_BINDING   =$8895
Const GL_STREAM_DRAW                    =$88E0
Const GL_STATIC_DRAW                    =$88E4
Const GL_DYNAMIC_DRAW                   =$88E8
Const GL_BUFFER_SIZE                    =$8764
Const GL_BUFFER_USAGE                   =$8765
Const GL_CURRENT_VERTEX_ATTRIB          =$8626
Const GL_FRONT                          =$0404
Const GL_BACK                           =$0405
Const GL_FRONT_AND_BACK                 =$0408
Const GL_TEXTURE_2D                     =$0DE1
Const GL_CULL_FACE                      =$0B44
Const GL_BLEND                          =$0BE2
Const GL_DITHER                         =$0BD0
Const GL_STENCIL_TEST                   =$0B90
Const GL_DEPTH_TEST                     =$0B71
Const GL_SCISSOR_TEST                   =$0C11
Const GL_POLYGON_OFFSET_FILL            =$8037
Const GL_SAMPLE_ALPHA_TO_COVERAGE       =$809E
Const GL_SAMPLE_COVERAGE                =$80A0
Const GL_NO_ERROR                       =0
Const GL_INVALID_ENUM                   =$0500
Const GL_INVALID_VALUE                  =$0501
Const GL_INVALID_OPERATION              =$0502
Const GL_OUT_OF_MEMORY                  =$0505
Const GL_CW                             =$0900
Const GL_CCW                            =$0901
Const GL_LINE_WIDTH                     =$0B21
Const GL_ALIASED_POINT_SIZE_RANGE       =$846D
Const GL_ALIASED_LINE_WIDTH_RANGE       =$846E
Const GL_CULL_FACE_MODE                 =$0B45
Const GL_FRONT_FACE                     =$0B46
Const GL_DEPTH_RANGE                    =$0B70
Const GL_DEPTH_WRITEMASK                =$0B72
Const GL_DEPTH_CLEAR_VALUE              =$0B73
Const GL_DEPTH_FUNC                     =$0B74
Const GL_STENCIL_CLEAR_VALUE            =$0B91
Const GL_STENCIL_FUNC                   =$0B92
Const GL_STENCIL_FAIL                   =$0B94
Const GL_STENCIL_PASS_DEPTH_FAIL        =$0B95
Const GL_STENCIL_PASS_DEPTH_PASS        =$0B96
Const GL_STENCIL_REF                    =$0B97
Const GL_STENCIL_VALUE_MASK             =$0B93
Const GL_STENCIL_WRITEMASK              =$0B98
Const GL_STENCIL_BACK_FUNC              =$8800
Const GL_STENCIL_BACK_FAIL              =$8801
Const GL_STENCIL_BACK_PASS_DEPTH_FAIL   =$8802
Const GL_STENCIL_BACK_PASS_DEPTH_PASS   =$8803
Const GL_STENCIL_BACK_REF               =$8CA3
Const GL_STENCIL_BACK_VALUE_MASK        =$8CA4
Const GL_STENCIL_BACK_WRITEMASK         =$8CA5
Const GL_VIEWPORT                       =$0BA2
Const GL_SCISSOR_BOX                    =$0C10
Const GL_COLOR_CLEAR_VALUE              =$0C22
Const GL_COLOR_WRITEMASK                =$0C23
Const GL_UNPACK_ALIGNMENT               =$0CF5
Const GL_PACK_ALIGNMENT                 =$0D05
Const GL_MAX_TEXTURE_SIZE               =$0D33
Const GL_MAX_VIEWPORT_DIMS              =$0D3A
Const GL_SUBPIXEL_BITS                  =$0D50
Const GL_RED_BITS                       =$0D52
Const GL_GREEN_BITS                     =$0D53
Const GL_BLUE_BITS                      =$0D54
Const GL_ALPHA_BITS                     =$0D55
Const GL_DEPTH_BITS                     =$0D56
Const GL_STENCIL_BITS                   =$0D57
Const GL_POLYGON_OFFSET_UNITS           =$2A00
Const GL_POLYGON_OFFSET_FACTOR          =$8038
Const GL_TEXTURE_BINDING_2D             =$8069
Const GL_SAMPLE_BUFFERS                 =$80A8
Const GL_SAMPLES                        =$80A9
Const GL_SAMPLE_COVERAGE_VALUE          =$80AA
Const GL_SAMPLE_COVERAGE_INVERT         =$80AB
Const GL_NUM_COMPRESSED_TEXTURE_FORMATS =$86A2
Const GL_COMPRESSED_TEXTURE_FORMATS     =$86A3
Const GL_DONT_CARE                      =$1100
Const GL_FASTEST                        =$1101
Const GL_NICEST                         =$1102
Const GL_GENERATE_MIPMAP_HINT            =$8192
Const GL_BYTE                           =$1400
Const GL_UNSIGNED_BYTE                  =$1401
Const GL_SHORT                          =$1402
Const GL_UNSIGNED_SHORT                 =$1403
Const GL_INT                            =$1404
Const GL_UNSIGNED_INT                   =$1405
Const GL_FLOAT                          =$1406
Const GL_FIXED                          =$140C
Const GL_DEPTH_COMPONENT                =$1902
Const GL_ALPHA                          =$1906
Const GL_RGB                            =$1907
Const GL_RGBA                           =$1908
Const GL_LUMINANCE                      =$1909
Const GL_LUMINANCE_ALPHA                =$190A
Const GL_UNSIGNED_SHORT_4_4_4_4         =$8033
Const GL_UNSIGNED_SHORT_5_5_5_1         =$8034
Const GL_UNSIGNED_SHORT_5_6_5           =$8363
Const GL_FRAGMENT_SHADER                  =$8B30
Const GL_VERTEX_SHADER                    =$8B31
Const GL_MAX_VERTEX_ATTRIBS               =$8869
Const GL_MAX_VERTEX_UNIFORM_VECTORS       =$8DFB
Const GL_MAX_VARYING_VECTORS              =$8DFC
Const GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS =$8B4D
Const GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS   =$8B4C
Const GL_MAX_TEXTURE_IMAGE_UNITS          =$8872
Const GL_MAX_FRAGMENT_UNIFORM_VECTORS     =$8DFD
Const GL_SHADER_TYPE                      =$8B4F
Const GL_DELETE_STATUS                    =$8B80
Const GL_LINK_STATUS                      =$8B82
Const GL_VALIDATE_STATUS                  =$8B83
Const GL_ATTACHED_SHADERS                 =$8B85
Const GL_ACTIVE_UNIFORMS                  =$8B86
Const GL_ACTIVE_UNIFORM_MAX_LENGTH        =$8B87
Const GL_ACTIVE_ATTRIBUTES                =$8B89
Const GL_ACTIVE_ATTRIBUTE_MAX_LENGTH      =$8B8A
Const GL_SHADING_LANGUAGE_VERSION         =$8B8C
Const GL_CURRENT_PROGRAM                  =$8B8D
Const GL_NEVER                          =$0200
Const GL_LESS                           =$0201
Const GL_EQUAL                          =$0202
Const GL_LEQUAL                         =$0203
Const GL_GREATER                        =$0204
Const GL_NOTEQUAL                       =$0205
Const GL_GEQUAL                         =$0206
Const GL_ALWAYS                         =$0207
Const GL_KEEP                           =$1E00
Const GL_REPLACE                        =$1E01
Const GL_INCR                           =$1E02
Const GL_DECR                           =$1E03
Const GL_INVERT                         =$150A
Const GL_INCR_WRAP                      =$8507
Const GL_DECR_WRAP                      =$8508
Const GL_VENDOR                         =$1F00
Const GL_RENDERER                       =$1F01
Const GL_VERSION                        =$1F02
Const GL_EXTENSIONS                     =$1F03
Const GL_NEAREST                        =$2600
Const GL_LINEAR                         =$2601
Const GL_NEAREST_MIPMAP_NEAREST         =$2700
Const GL_LINEAR_MIPMAP_NEAREST          =$2701
Const GL_NEAREST_MIPMAP_LINEAR          =$2702
Const GL_LINEAR_MIPMAP_LINEAR           =$2703
Const GL_TEXTURE_MAG_FILTER             =$2800
Const GL_TEXTURE_MIN_FILTER             =$2801
Const GL_TEXTURE_WRAP_S                 =$2802
Const GL_TEXTURE_WRAP_T                 =$2803
Const GL_TEXTURE                        =$1702
Const GL_TEXTURE_CUBE_MAP               =$8513
Const GL_TEXTURE_BINDING_CUBE_MAP       =$8514
Const GL_TEXTURE_CUBE_MAP_POSITIVE_X    =$8515
Const GL_TEXTURE_CUBE_MAP_NEGATIVE_X    =$8516
Const GL_TEXTURE_CUBE_MAP_POSITIVE_Y    =$8517
Const GL_TEXTURE_CUBE_MAP_NEGATIVE_Y    =$8518
Const GL_TEXTURE_CUBE_MAP_POSITIVE_Z    =$8519
Const GL_TEXTURE_CUBE_MAP_NEGATIVE_Z    =$851A
Const GL_MAX_CUBE_MAP_TEXTURE_SIZE      =$851C
Const GL_TEXTURE0                       =$84C0
Const GL_TEXTURE1                       =$84C1
Const GL_TEXTURE2                       =$84C2
Const GL_TEXTURE3                       =$84C3
Const GL_TEXTURE4                       =$84C4
Const GL_TEXTURE5                       =$84C5
Const GL_TEXTURE6                       =$84C6
Const GL_TEXTURE7                       =$84C7
Const GL_TEXTURE8                       =$84C8
Const GL_TEXTURE9                       =$84C9
Const GL_TEXTURE10                      =$84CA
Const GL_TEXTURE11                      =$84CB
Const GL_TEXTURE12                      =$84CC
Const GL_TEXTURE13                      =$84CD
Const GL_TEXTURE14                      =$84CE
Const GL_TEXTURE15                      =$84CF
Const GL_TEXTURE16                      =$84D0
Const GL_TEXTURE17                      =$84D1
Const GL_TEXTURE18                      =$84D2
Const GL_TEXTURE19                      =$84D3
Const GL_TEXTURE20                      =$84D4
Const GL_TEXTURE21                      =$84D5
Const GL_TEXTURE22                      =$84D6
Const GL_TEXTURE23                      =$84D7
Const GL_TEXTURE24                      =$84D8
Const GL_TEXTURE25                      =$84D9
Const GL_TEXTURE26                      =$84DA
Const GL_TEXTURE27                      =$84DB
Const GL_TEXTURE28                      =$84DC
Const GL_TEXTURE29                      =$84DD
Const GL_TEXTURE30                      =$84DE
Const GL_TEXTURE31                      =$84DF
Const GL_ACTIVE_TEXTURE                 =$84E0
Const GL_REPEAT                         =$2901
Const GL_CLAMP_TO_EDGE                  =$812F
Const GL_MIRRORED_REPEAT                =$8370
Const GL_FLOAT_VEC2                     =$8B50
Const GL_FLOAT_VEC3                     =$8B51
Const GL_FLOAT_VEC4                     =$8B52
Const GL_INT_VEC2                       =$8B53
Const GL_INT_VEC3                       =$8B54
Const GL_INT_VEC4                       =$8B55
Const GL_BOOL                           =$8B56
Const GL_BOOL_VEC2                      =$8B57
Const GL_BOOL_VEC3                      =$8B58
Const GL_BOOL_VEC4                      =$8B59
Const GL_FLOAT_MAT2                     =$8B5A
Const GL_FLOAT_MAT3                     =$8B5B
Const GL_FLOAT_MAT4                     =$8B5C
Const GL_SAMPLER_2D                     =$8B5E
Const GL_SAMPLER_CUBE                   =$8B60
Const GL_VERTEX_ATTRIB_ARRAY_ENABLED        =$8622
Const GL_VERTEX_ATTRIB_ARRAY_SIZE           =$8623
Const GL_VERTEX_ATTRIB_ARRAY_STRIDE         =$8624
Const GL_VERTEX_ATTRIB_ARRAY_TYPE           =$8625
Const GL_VERTEX_ATTRIB_ARRAY_NORMALIZED     =$886A
Const GL_VERTEX_ATTRIB_ARRAY_POINTER        =$8645
Const GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING =$889F
Const GL_IMPLEMENTATION_COLOR_READ_TYPE   =$8B9A
Const GL_IMPLEMENTATION_COLOR_READ_FORMAT =$8B9B
Const GL_COMPILE_STATUS                 =$8B81
Const GL_INFO_LOG_LENGTH                =$8B84
Const GL_SHADER_SOURCE_LENGTH           =$8B88
Const GL_SHADER_COMPILER                =$8DFA
Const GL_SHADER_BINARY_FORMATS          =$8DF8
Const GL_NUM_SHADER_BINARY_FORMATS      =$8DF9
Const GL_LOW_FLOAT                      =$8DF0
Const GL_MEDIUM_FLOAT                   =$8DF1
Const GL_HIGH_FLOAT                     =$8DF2
Const GL_LOW_INT                        =$8DF3
Const GL_MEDIUM_INT                     =$8DF4
Const GL_HIGH_INT                       =$8DF5
Const GL_FRAMEBUFFER                    =$8D40
Const GL_RENDERBUFFER                   =$8D41
Const GL_RGBA4                          =$8056
Const GL_RGB5_A1                        =$8057
Const GL_RGB565                         =$8D62
Const GL_DEPTH_COMPONENT16              =$81A5
Const GL_STENCIL_INDEX                  =$1901
Const GL_STENCIL_INDEX8                 =$8D48
Const GL_RENDERBUFFER_WIDTH             =$8D42
Const GL_RENDERBUFFER_HEIGHT            =$8D43
Const GL_RENDERBUFFER_INTERNAL_FORMAT   =$8D44
Const GL_RENDERBUFFER_RED_SIZE          =$8D50
Const GL_RENDERBUFFER_GREEN_SIZE        =$8D51
Const GL_RENDERBUFFER_BLUE_SIZE         =$8D52
Const GL_RENDERBUFFER_ALPHA_SIZE        =$8D53
Const GL_RENDERBUFFER_DEPTH_SIZE        =$8D54
Const GL_RENDERBUFFER_STENCIL_SIZE      =$8D55
Const GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE           =$8CD0
Const GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME           =$8CD1
Const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL         =$8CD2
Const GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE =$8CD3
Const GL_COLOR_ATTACHMENT0              =$8CE0
Const GL_DEPTH_ATTACHMENT               =$8D00
Const GL_STENCIL_ATTACHMENT             =$8D20
Const GL_NONE                           =0
Const GL_FRAMEBUFFER_COMPLETE                      =$8CD5
Const GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT         =$8CD6
Const GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT =$8CD7
Const GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS         =$8CD9
Const GL_FRAMEBUFFER_UNSUPPORTED                   =$8CDD
Const GL_FRAMEBUFFER_BINDING            =$8CA6
Const GL_RENDERBUFFER_BINDING           =$8CA7
Const GL_MAX_RENDERBUFFER_SIZE          =$84E8
Const GL_INVALID_FRAMEBUFFER_OPERATION  =$0506
'${END}

Extern

#If TARGET="glfw"

Function BBLoadImageData:BBDataBuffer( buf:BBDataBuffer,path$,info[]=[] )="BBLoadImageData"

'${GLFW_DECLS}
Function glActiveTexture:Void( texture )
Function glAttachShader:Void( program, shader )
Function glBindAttribLocation:Void( program, index, name$ )="_glBindAttribLocation"
Function glBindBuffer:Void( target, buffer )
Function glBindFramebuffer:Void( target, framebuffer )
Function glBindRenderbuffer:Void( target, renderbuffer )
Function glBindTexture:Void( target, texture )
Function glBlendColor:Void( red#, green#, blue#, alpha# )
Function glBlendEquation:Void(  mode  )
Function glBlendEquationSeparate:Void( modeRGB, modeAlpha )
Function glBlendFunc:Void( sfactor, dfactor )
Function glBlendFuncSeparate:Void( srcRGB, dstRGB, srcAlpha, dstAlpha )
Function glBufferData:Void( target, size, data:DataBuffer, usage )="_glBufferData"
Function glBufferSubData:Void( target, offset, size, data:DataBuffer )="_glBufferSubData"
Function glCheckFramebufferStatus:Int( target )
Function glClear:Void( mask )
Function glClearColor:Void( red#, green#, blue#, alpha# )
Function glClearDepthf:Void( depth# )="_glClearDepthf"
Function glClearStencil:Void( s )
Function glColorMask:Void( red?, green?, blue?, alpha? )
Function glCompileShader:Void( shader )
Function glCopyTexImage2D:Void( target, level, internalformat, x, y, width, height, border )
Function glCopyTexSubImage2D:Void( target, level, xoffset, yoffset, x, y, width, height )
Function glCreateBuffer:Int()="_glCreateBuffer"
Function glCreateFramebuffer:Int()="_glCreateFramebuffer"
Function glCreateRenderbuffer:Int()="_glCreateRenderbuffer"
Function glCreateTexture:Int()="_glCreateTexture"
Function glCreateProgram:Int()
Function glCreateShader:Int( type )
Function glDeleteBuffer:Void( buffer )="_glDeleteBuffer"
Function glDeleteFramebuffer:Void( framebuffer )="_glDeleteFramebuffer"
Function glDeleteRenderbuffer:Void( renderBuffer )="_glDeleteRenderbuffer"
Function glDeleteTexture:Void( texture )="_glDeleteTexture"
Function glDeleteProgram:Void( program )
Function glDeleteShader:Void( shader )
Function glCullFace:Void( mode )
Function glDepthFunc:Void( func )
Function glDepthMask:Void( flag? )
Function glDepthRangef:Void( zNear#, zFar# )="_glDepthRangef"
Function glDetachShader:Void( program, shader )
Function glDisable:Void( cap )
Function glDisableVertexAttribArray:Void( index )
Function glDrawArrays:Void( mode, first, count )
Function glDrawElements:Void( mode, count, type, ptr:DataBuffer )="_glDrawElements"
Function glDrawElements:Void( mode, count, type, offset )="_glDrawElements"
Function glEnable:Void( cap )
Function glEnableVertexAttribArray:Void( index )
Function glFinish:Void()
Function glFlush:Void()
Function glFramebufferRenderbuffer:Void( target, attachment, renderbuffertarget, renderbuffer )
Function glFramebufferTexture2D:Void( target, attachment, textarget, texture, level )
Function glFrontFace:Void( mode )
Function glGenerateMipmap:Void( target )
Function glGetActiveAttrib:Void( program, index, size[], type[], name$[] )="_glGetActiveAttrib"
Function glGetActiveUniform:Void( program, index, size[], type[], name$[] )="_glGetActiveUniform"
Function glGetAttachedShaders:Void( program, maxcount, count[], shaders[] )="_glGetAttachedShaders"
Function glGetAttribLocation:Int( program, name$ )="_glGetAttribLocation"
Function glGetBooleanv:Void( pname, params?[] )="_glGetBooleanv"
Function glGetBufferParameteriv:Void( target, pname, params[] )="_glGetBufferParameteriv"
Function glGetError:Int()
Function glGetFloatv:Void( pname, params#[] )="_glGetFloatv"
Function glGetFramebufferAttachmentParameteriv:Void( target, attachment, pname, params[] )="_glGetFramebufferAttachmentParameteriv"
Function glGetIntegerv:Void( pname, params[] )="_glGetIntegerv"
Function glGetProgramiv:Void( program, pname, params[] )="_glGetProgramiv"
Function glGetProgramInfoLog:String( program )="_glGetProgramInfoLog"
Function glGetRenderbufferParameteriv:Void( target, pname, params[] )="_glGetRenderbufferParameteriv"
Function glGetShaderiv:Void( shader, pname, params[] )="_glGetShaderiv"
Function glGetShaderInfoLog:String( shader )="_glGetShaderInfoLog"
Function glGetShaderSource:String( shader )="_glGetShaderSource"
Function glGetString:String( name )="_glGetString"
Function glGetTexParameterfv:Void( target, pname, params#[] )="_glGetTexParameterfv"
Function glGetTexParameteriv:Void( target, pname, params[] )="_glGetTexParameteriv"
Function glGetUniformfv:Void( program, location, params#[] )="_glGetUniformfv"
Function glGetUniformiv:Void( program, location, params[] )="_glGetUniformiv"
Function glGetUniformLocation:Int( program, name$ )="_glGetUniformLocation"
Function glGetVertexAttribfv:Void( index, pname, params#[] )="_glGetVertexAttribfv"
Function glGetVertexAttribiv:Void( index, pname, params[] )="_glGetVertexAttribiv"
Function glHint:Void( target, mode )
Function glIsBuffer:Bool( buffer )
Function glIsEnabled:Bool( cap )
Function glIsFramebuffer:Bool( framebuffer )
Function glIsProgram:Bool( program )
Function glIsRenderbuffer:Bool( renderbuffer )
Function glIsShader:Bool( shader )
Function glIsTexture:Bool( texture )
Function glLineWidth:Void( width# )
Function glLinkProgram:Void( program )
Function glPixelStorei:Void( pname, param )
Function glPolygonOffset:Void( factor#, units# )
Function glReadPixels:Void( x, y, width, height, format, type, pixels:DataBuffer )="_glReadPixels"
Function glReleaseShaderCompiler:Void()
Function glRenderbufferStorage:Void( target, internalformat, width, height )
Function glSampleCoverage:Void( value#, invert? )
Function glScissor:Void( x, y, width, height )
Function glShaderSource:Void( shader, source$ )="_glShaderSource"
Function glStencilFunc:Void( func, ref, mask )
Function glStencilFuncSeparate:Void( face, func, ref, mask )
Function glStencilMask:Void( mask )
Function glStencilMaskSeparate:Void( face, mask )
Function glStencilOp:Void( fail, zfail, zpass )
Function glStencilOpSeparate:Void( face, fail, zfail, zpass )
Function glTexImage2D:Void( target, level, internalformat, width, height, border, format, type, pixels:DataBuffer )="_glTexImage2D"
Function glTexSubImage2D:Void( target, level, xoffset, yoffset, width, height, format, type, pixels:DataBuffer )="_glTexSubImage2D"
Function glTexParameterf:Void( target, pname, param# )
Function glTexParameteri:Void( target, pname, param )
Function glUniform1f:Void( location, x# )
Function glUniform1i:Void( location, x )
Function glUniform2f:Void( location, x#, y# )
Function glUniform2i:Void( location, x, y )
Function glUniform3f:Void( location, x#, y#, z# )
Function glUniform3i:Void( location, x, y, z )
Function glUniform4f:Void( location, x#, y#, z#, w# )
Function glUniform4i:Void( location, x, y, z, w )
Function glUniform1fv:Void( location, count, v#[] )="_glUniform1fv"
Function glUniform1iv:Void( location, count, v[] )="_glUniform1iv"
Function glUniform2fv:Void( location, count, v#[] )="_glUniform2fv"
Function glUniform2iv:Void( location, count, v[] )="_glUniform2iv"
Function glUniform3fv:Void( location, count, v#[] )="_glUniform3fv"
Function glUniform3iv:Void( location, count, v[] )="_glUniform3iv"
Function glUniform4fv:Void( location, count, v#[] )="_glUniform4fv"
Function glUniform4iv:Void( location, count, v[] )="_glUniform4iv"
Function glUniformMatrix2fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix2fv"
Function glUniformMatrix3fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix3fv"
Function glUniformMatrix4fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix4fv"
Function glUseProgram:Void( program )
Function glValidateProgram:Void( program )
Function glVertexAttrib1f:Void( indx, x# )
Function glVertexAttrib2f:Void( indx, x#, y# )
Function glVertexAttrib3f:Void( indx, x#, y#, z# )
Function glVertexAttrib4f:Void( indx, x#, y#, z#, w# )
Function glVertexAttrib1fv:Void( indx, values#[] )="_glVertexAttrib1fv"
Function glVertexAttrib2fv:Void( indx, values#[] )="_glVertexAttrib2fv"
Function glVertexAttrib3fv:Void( indx, values#[] )="_glVertexAttrib3fv"
Function glVertexAttrib4fv:Void( indx, values#[] )="_glVertexAttrib4fv"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, data:DataBuffer )="_glVertexAttribPointer"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, offset )="_glVertexAttribPointer"
Function glViewport:Void( x, y, width, height )
'${END}

#Elseif TARGET="android"

Function BBLoadImageData:BBDataBuffer( buf:BBDataBuffer,path$,info[]=[] )="bb_opengl_gles20.LoadImageData"

'${ANDROID_DECLS}
Function glActiveTexture:Void( texture )="GLES20.glActiveTexture"
Function glAttachShader:Void( program, shader )="GLES20.glAttachShader"
Function glBindAttribLocation:Void( program, index, name$ )="GLES20.glBindAttribLocation"
Function glBindBuffer:Void( target, buffer )="GLES20.glBindBuffer"
Function glBindFramebuffer:Void( target, framebuffer )="GLES20.glBindFramebuffer"
Function glBindRenderbuffer:Void( target, renderbuffer )="GLES20.glBindRenderbuffer"
Function glBindTexture:Void( target, texture )="GLES20.glBindTexture"
Function glBlendColor:Void( red#, green#, blue#, alpha# )="GLES20.glBlendColor"
Function glBlendEquation:Void(  mode  )="GLES20.glBlendEquation"
Function glBlendEquationSeparate:Void( modeRGB, modeAlpha )="GLES20.glBlendEquationSeparate"
Function glBlendFunc:Void( sfactor, dfactor )="GLES20.glBlendFunc"
Function glBlendFuncSeparate:Void( srcRGB, dstRGB, srcAlpha, dstAlpha )="GLES20.glBlendFuncSeparate"
Function glBufferData:Void( target, size, data:DataBuffer, usage )="bb_opengl_gles20._glBufferData"
Function glBufferSubData:Void( target, offset, size, data:DataBuffer )="bb_opengl_gles20._glBufferSubData"
Function glCheckFramebufferStatus:Int( target )="GLES20.glCheckFramebufferStatus"
Function glClear:Void( mask )="GLES20.glClear"
Function glClearColor:Void( red#, green#, blue#, alpha# )="GLES20.glClearColor"
Function glClearDepthf:Void( depth# )="GLES20.glClearDepthf"
Function glClearStencil:Void( s )="GLES20.glClearStencil"
Function glColorMask:Void( red?, green?, blue?, alpha? )="GLES20.glColorMask"
Function glCompileShader:Void( shader )="GLES20.glCompileShader"
Function glCopyTexImage2D:Void( target, level, internalformat, x, y, width, height, border )="GLES20.glCopyTexImage2D"
Function glCopyTexSubImage2D:Void( target, level, xoffset, yoffset, x, y, width, height )="GLES20.glCopyTexSubImage2D"
Function glCreateBuffer:Int()="bb_opengl_gles20._glCreateBuffer"
Function glCreateFramebuffer:Int()="bb_opengl_gles20._glCreateFramebuffer"
Function glCreateRenderbuffer:Int()="bb_opengl_gles20._glCreateRenderbuffer"
Function glCreateTexture:Int()="bb_opengl_gles20._glCreateTexture"
Function glCreateProgram:Int()="GLES20.glCreateProgram"
Function glCreateShader:Int( type )="GLES20.glCreateShader"
Function glDeleteBuffer:Void( buffer )="bb_opengl_gles20._glDeleteBuffer"
Function glDeleteFramebuffer:Void( framebuffer )="bb_opengl_gles20._glDeleteFramebuffer"
Function glDeleteRenderbuffer:Void( renderBuffer )="bb_opengl_gles20._glDeleteRenderbuffer"
Function glDeleteTexture:Void( texture )="bb_opengl_gles20._glDeleteTexture"
Function glDeleteProgram:Void( program )="GLES20.glDeleteProgram"
Function glDeleteShader:Void( shader )="GLES20.glDeleteShader"
Function glCullFace:Void( mode )="GLES20.glCullFace"
Function glDepthFunc:Void( func )="GLES20.glDepthFunc"
Function glDepthMask:Void( flag? )="GLES20.glDepthMask"
Function glDepthRangef:Void( zNear#, zFar# )="GLES20.glDepthRangef"
Function glDetachShader:Void( program, shader )="GLES20.glDetachShader"
Function glDisable:Void( cap )="GLES20.glDisable"
Function glDisableVertexAttribArray:Void( index )="GLES20.glDisableVertexAttribArray"
Function glDrawArrays:Void( mode, first, count )="GLES20.glDrawArrays"
Function glDrawElements:Void( mode, count, type, ptr:DataBuffer )="bb_opengl_gles20._glDrawElements"
Function glDrawElements:Void( mode, count, type, offset )="bb_opengl_gles20._glDrawElements"
Function glEnable:Void( cap )="GLES20.glEnable"
Function glEnableVertexAttribArray:Void( index )="GLES20.glEnableVertexAttribArray"
Function glFinish:Void()="GLES20.glFinish"
Function glFlush:Void()="GLES20.glFlush"
Function glFramebufferRenderbuffer:Void( target, attachment, renderbuffertarget, renderbuffer )="GLES20.glFramebufferRenderbuffer"
Function glFramebufferTexture2D:Void( target, attachment, textarget, texture, level )="GLES20.glFramebufferTexture2D"
Function glFrontFace:Void( mode )="GLES20.glFrontFace"
Function glGenerateMipmap:Void( target )="GLES20.glGenerateMipmap"
Function glGetActiveAttrib:Void( program, index, size[], type[], name$[] )="bb_opengl_gles20._glGetActiveAttrib"
Function glGetActiveUniform:Void( program, index, size[], type[], name$[] )="bb_opengl_gles20._glGetActiveUniform"
Function glGetAttachedShaders:Void( program, maxcount, count[], shaders[] )="bb_opengl_gles20._glGetAttachedShaders"
Function glGetAttribLocation:Int( program, name$ )="GLES20.glGetAttribLocation"
Function glGetBooleanv:Void( pname, params?[] )="bb_opengl_gles20._glGetBooleanv"
Function glGetBufferParameteriv:Void( target, pname, params[] )="bb_opengl_gles20._glGetBufferParameteriv"
Function glGetError:Int()="GLES20.glGetError"
Function glGetFloatv:Void( pname, params#[] )="bb_opengl_gles20._glGetFloatv"
Function glGetFramebufferAttachmentParameteriv:Void( target, attachment, pname, params[] )="bb_opengl_gles20._glGetFramebufferAttachmentParameteriv"
Function glGetIntegerv:Void( pname, params[] )="bb_opengl_gles20._glGetIntegerv"
Function glGetProgramiv:Void( program, pname, params[] )="bb_opengl_gles20._glGetProgramiv"
Function glGetProgramInfoLog:String( program )="GLES20.glGetProgramInfoLog"
Function glGetRenderbufferParameteriv:Void( target, pname, params[] )="bb_opengl_gles20._glGetRenderbufferParameteriv"
Function glGetShaderiv:Void( shader, pname, params[] )="bb_opengl_gles20._glGetShaderiv"
Function glGetShaderInfoLog:String( shader )="GLES20.glGetShaderInfoLog"
Function glGetShaderSource:String( shader )="bb_opengl_gles20._glGetShaderSource"
Function glGetString:String( name )="GLES20.glGetString"
Function glGetTexParameterfv:Void( target, pname, params#[] )="bb_opengl_gles20._glGetTexParameterfv"
Function glGetTexParameteriv:Void( target, pname, params[] )="bb_opengl_gles20._glGetTexParameteriv"
Function glGetUniformfv:Void( program, location, params#[] )="bb_opengl_gles20._glGetUniformfv"
Function glGetUniformiv:Void( program, location, params[] )="bb_opengl_gles20._glGetUniformiv"
Function glGetUniformLocation:Int( program, name$ )="GLES20.glGetUniformLocation"
Function glGetVertexAttribfv:Void( index, pname, params#[] )="bb_opengl_gles20._glGetVertexAttribfv"
Function glGetVertexAttribiv:Void( index, pname, params[] )="bb_opengl_gles20._glGetVertexAttribiv"
Function glHint:Void( target, mode )="GLES20.glHint"
Function glIsBuffer:Bool( buffer )="GLES20.glIsBuffer"
Function glIsEnabled:Bool( cap )="GLES20.glIsEnabled"
Function glIsFramebuffer:Bool( framebuffer )="GLES20.glIsFramebuffer"
Function glIsProgram:Bool( program )="GLES20.glIsProgram"
Function glIsRenderbuffer:Bool( renderbuffer )="GLES20.glIsRenderbuffer"
Function glIsShader:Bool( shader )="GLES20.glIsShader"
Function glIsTexture:Bool( texture )="GLES20.glIsTexture"
Function glLineWidth:Void( width# )="GLES20.glLineWidth"
Function glLinkProgram:Void( program )="GLES20.glLinkProgram"
Function glPixelStorei:Void( pname, param )="GLES20.glPixelStorei"
Function glPolygonOffset:Void( factor#, units# )="GLES20.glPolygonOffset"
Function glReadPixels:Void( x, y, width, height, format, type, pixels:DataBuffer )="bb_opengl_gles20._glReadPixels"
Function glReleaseShaderCompiler:Void()="GLES20.glReleaseShaderCompiler"
Function glRenderbufferStorage:Void( target, internalformat, width, height )="GLES20.glRenderbufferStorage"
Function glSampleCoverage:Void( value#, invert? )="GLES20.glSampleCoverage"
Function glScissor:Void( x, y, width, height )="GLES20.glScissor"
Function glShaderSource:Void( shader, source$ )="GLES20.glShaderSource"
Function glStencilFunc:Void( func, ref, mask )="GLES20.glStencilFunc"
Function glStencilFuncSeparate:Void( face, func, ref, mask )="GLES20.glStencilFuncSeparate"
Function glStencilMask:Void( mask )="GLES20.glStencilMask"
Function glStencilMaskSeparate:Void( face, mask )="GLES20.glStencilMaskSeparate"
Function glStencilOp:Void( fail, zfail, zpass )="GLES20.glStencilOp"
Function glStencilOpSeparate:Void( face, fail, zfail, zpass )="GLES20.glStencilOpSeparate"
Function glTexImage2D:Void( target, level, internalformat, width, height, border, format, type, pixels:DataBuffer )="bb_opengl_gles20._glTexImage2D"
Function glTexSubImage2D:Void( target, level, xoffset, yoffset, width, height, format, type, pixels:DataBuffer )="bb_opengl_gles20._glTexSubImage2D"
Function glTexParameterf:Void( target, pname, param# )="GLES20.glTexParameterf"
Function glTexParameteri:Void( target, pname, param )="GLES20.glTexParameteri"
Function glUniform1f:Void( location, x# )="GLES20.glUniform1f"
Function glUniform1i:Void( location, x )="GLES20.glUniform1i"
Function glUniform2f:Void( location, x#, y# )="GLES20.glUniform2f"
Function glUniform2i:Void( location, x, y )="GLES20.glUniform2i"
Function glUniform3f:Void( location, x#, y#, z# )="GLES20.glUniform3f"
Function glUniform3i:Void( location, x, y, z )="GLES20.glUniform3i"
Function glUniform4f:Void( location, x#, y#, z#, w# )="GLES20.glUniform4f"
Function glUniform4i:Void( location, x, y, z, w )="GLES20.glUniform4i"
Function glUniform1fv:Void( location, count, v#[] )="bb_opengl_gles20._glUniform1fv"
Function glUniform1iv:Void( location, count, v[] )="bb_opengl_gles20._glUniform1iv"
Function glUniform2fv:Void( location, count, v#[] )="bb_opengl_gles20._glUniform2fv"
Function glUniform2iv:Void( location, count, v[] )="bb_opengl_gles20._glUniform2iv"
Function glUniform3fv:Void( location, count, v#[] )="bb_opengl_gles20._glUniform3fv"
Function glUniform3iv:Void( location, count, v[] )="bb_opengl_gles20._glUniform3iv"
Function glUniform4fv:Void( location, count, v#[] )="bb_opengl_gles20._glUniform4fv"
Function glUniform4iv:Void( location, count, v[] )="bb_opengl_gles20._glUniform4iv"
Function glUniformMatrix2fv:Void( location, count, transpose?, value#[] )="bb_opengl_gles20._glUniformMatrix2fv"
Function glUniformMatrix3fv:Void( location, count, transpose?, value#[] )="bb_opengl_gles20._glUniformMatrix3fv"
Function glUniformMatrix4fv:Void( location, count, transpose?, value#[] )="bb_opengl_gles20._glUniformMatrix4fv"
Function glUseProgram:Void( program )="GLES20.glUseProgram"
Function glValidateProgram:Void( program )="GLES20.glValidateProgram"
Function glVertexAttrib1f:Void( indx, x# )="GLES20.glVertexAttrib1f"
Function glVertexAttrib2f:Void( indx, x#, y# )="GLES20.glVertexAttrib2f"
Function glVertexAttrib3f:Void( indx, x#, y#, z# )="GLES20.glVertexAttrib3f"
Function glVertexAttrib4f:Void( indx, x#, y#, z#, w# )="GLES20.glVertexAttrib4f"
Function glVertexAttrib1fv:Void( indx, values#[] )="bb_opengl_gles20._glVertexAttrib1fv"
Function glVertexAttrib2fv:Void( indx, values#[] )="bb_opengl_gles20._glVertexAttrib2fv"
Function glVertexAttrib3fv:Void( indx, values#[] )="bb_opengl_gles20._glVertexAttrib3fv"
Function glVertexAttrib4fv:Void( indx, values#[] )="bb_opengl_gles20._glVertexAttrib4fv"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, data:DataBuffer )="bb_opengl_gles20._glVertexAttribPointer"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, offset )="bb_opengl_gles20._glVertexAttribPointer"
Function glViewport:Void( x, y, width, height )="GLES20.glViewport"
'${END}

#ElseIf TARGET="ios"

Function BBLoadImageData:BBDataBuffer( buf:BBDataBuffer,path$,info[]=[] )="LoadImageData"

'${IOS_DECLS}
Function glActiveTexture:Void( texture )
Function glAttachShader:Void( program, shader )
Function glBindAttribLocation:Void( program, index, name$ )="_glBindAttribLocation"
Function glBindBuffer:Void( target, buffer )
Function glBindFramebuffer:Void( target, framebuffer )
Function glBindRenderbuffer:Void( target, renderbuffer )
Function glBindTexture:Void( target, texture )
Function glBlendColor:Void( red#, green#, blue#, alpha# )
Function glBlendEquation:Void(  mode  )
Function glBlendEquationSeparate:Void( modeRGB, modeAlpha )
Function glBlendFunc:Void( sfactor, dfactor )
Function glBlendFuncSeparate:Void( srcRGB, dstRGB, srcAlpha, dstAlpha )
Function glBufferData:Void( target, size, data:DataBuffer, usage )="_glBufferData"
Function glBufferSubData:Void( target, offset, size, data:DataBuffer )="_glBufferSubData"
Function glCheckFramebufferStatus:Int( target )
Function glClear:Void( mask )
Function glClearColor:Void( red#, green#, blue#, alpha# )
Function glClearDepthf:Void( depth# )
Function glClearStencil:Void( s )
Function glColorMask:Void( red?, green?, blue?, alpha? )
Function glCompileShader:Void( shader )
Function glCopyTexImage2D:Void( target, level, internalformat, x, y, width, height, border )
Function glCopyTexSubImage2D:Void( target, level, xoffset, yoffset, x, y, width, height )
Function glCreateBuffer:Int()="_glCreateBuffer"
Function glCreateFramebuffer:Int()="_glCreateFramebuffer"
Function glCreateRenderbuffer:Int()="_glCreateRenderbuffer"
Function glCreateTexture:Int()="_glCreateTexture"
Function glCreateProgram:Int()
Function glCreateShader:Int( type )
Function glDeleteBuffer:Void( buffer )="_glDeleteBuffer"
Function glDeleteFramebuffer:Void( framebuffer )="_glDeleteFramebuffer"
Function glDeleteRenderbuffer:Void( renderBuffer )="_glDeleteRenderbuffer"
Function glDeleteTexture:Void( texture )="_glDeleteTexture"
Function glDeleteProgram:Void( program )
Function glDeleteShader:Void( shader )
Function glCullFace:Void( mode )
Function glDepthFunc:Void( func )
Function glDepthMask:Void( flag? )
Function glDepthRangef:Void( zNear#, zFar# )
Function glDetachShader:Void( program, shader )
Function glDisable:Void( cap )
Function glDisableVertexAttribArray:Void( index )
Function glDrawArrays:Void( mode, first, count )
Function glDrawElements:Void( mode, count, type, ptr:DataBuffer )="_glDrawElements"
Function glDrawElements:Void( mode, count, type, offset )="_glDrawElements"
Function glEnable:Void( cap )
Function glEnableVertexAttribArray:Void( index )
Function glFinish:Void()
Function glFlush:Void()
Function glFramebufferRenderbuffer:Void( target, attachment, renderbuffertarget, renderbuffer )
Function glFramebufferTexture2D:Void( target, attachment, textarget, texture, level )
Function glFrontFace:Void( mode )
Function glGenerateMipmap:Void( target )
Function glGetActiveAttrib:Void( program, index, size[], type[], name$[] )="_glGetActiveAttrib"
Function glGetActiveUniform:Void( program, index, size[], type[], name$[] )="_glGetActiveUniform"
Function glGetAttachedShaders:Void( program, maxcount, count[], shaders[] )="_glGetAttachedShaders"
Function glGetAttribLocation:Int( program, name$ )="_glGetAttribLocation"
Function glGetBooleanv:Void( pname, params?[] )="_glGetBooleanv"
Function glGetBufferParameteriv:Void( target, pname, params[] )="_glGetBufferParameteriv"
Function glGetError:Int()
Function glGetFloatv:Void( pname, params#[] )="_glGetFloatv"
Function glGetFramebufferAttachmentParameteriv:Void( target, attachment, pname, params[] )="_glGetFramebufferAttachmentParameteriv"
Function glGetIntegerv:Void( pname, params[] )="_glGetIntegerv"
Function glGetProgramiv:Void( program, pname, params[] )="_glGetProgramiv"
Function glGetProgramInfoLog:String( program )="_glGetProgramInfoLog"
Function glGetRenderbufferParameteriv:Void( target, pname, params[] )="_glGetRenderbufferParameteriv"
Function glGetShaderiv:Void( shader, pname, params[] )="_glGetShaderiv"
Function glGetShaderInfoLog:String( shader )="_glGetShaderInfoLog"
Function glGetShaderSource:String( shader )="_glGetShaderSource"
Function glGetString:String( name )="_glGetString"
Function glGetTexParameterfv:Void( target, pname, params#[] )="_glGetTexParameterfv"
Function glGetTexParameteriv:Void( target, pname, params[] )="_glGetTexParameteriv"
Function glGetUniformfv:Void( program, location, params#[] )="_glGetUniformfv"
Function glGetUniformiv:Void( program, location, params[] )="_glGetUniformiv"
Function glGetUniformLocation:Int( program, name$ )="_glGetUniformLocation"
Function glGetVertexAttribfv:Void( index, pname, params#[] )="_glGetVertexAttribfv"
Function glGetVertexAttribiv:Void( index, pname, params[] )="_glGetVertexAttribiv"
Function glHint:Void( target, mode )
Function glIsBuffer:Bool( buffer )
Function glIsEnabled:Bool( cap )
Function glIsFramebuffer:Bool( framebuffer )
Function glIsProgram:Bool( program )
Function glIsRenderbuffer:Bool( renderbuffer )
Function glIsShader:Bool( shader )
Function glIsTexture:Bool( texture )
Function glLineWidth:Void( width# )
Function glLinkProgram:Void( program )
Function glPixelStorei:Void( pname, param )
Function glPolygonOffset:Void( factor#, units# )
Function glReadPixels:Void( x, y, width, height, format, type, pixels:DataBuffer )="_glReadPixels"
Function glReleaseShaderCompiler:Void()
Function glRenderbufferStorage:Void( target, internalformat, width, height )
Function glSampleCoverage:Void( value#, invert? )
Function glScissor:Void( x, y, width, height )
Function glShaderSource:Void( shader, source$ )="_glShaderSource"
Function glStencilFunc:Void( func, ref, mask )
Function glStencilFuncSeparate:Void( face, func, ref, mask )
Function glStencilMask:Void( mask )
Function glStencilMaskSeparate:Void( face, mask )
Function glStencilOp:Void( fail, zfail, zpass )
Function glStencilOpSeparate:Void( face, fail, zfail, zpass )
Function glTexImage2D:Void( target, level, internalformat, width, height, border, format, type, pixels:DataBuffer )="_glTexImage2D"
Function glTexSubImage2D:Void( target, level, xoffset, yoffset, width, height, format, type, pixels:DataBuffer )="_glTexSubImage2D"
Function glTexParameterf:Void( target, pname, param# )
Function glTexParameteri:Void( target, pname, param )
Function glUniform1f:Void( location, x# )
Function glUniform1i:Void( location, x )
Function glUniform2f:Void( location, x#, y# )
Function glUniform2i:Void( location, x, y )
Function glUniform3f:Void( location, x#, y#, z# )
Function glUniform3i:Void( location, x, y, z )
Function glUniform4f:Void( location, x#, y#, z#, w# )
Function glUniform4i:Void( location, x, y, z, w )
Function glUniform1fv:Void( location, count, v#[] )="_glUniform1fv"
Function glUniform1iv:Void( location, count, v[] )="_glUniform1iv"
Function glUniform2fv:Void( location, count, v#[] )="_glUniform2fv"
Function glUniform2iv:Void( location, count, v[] )="_glUniform2iv"
Function glUniform3fv:Void( location, count, v#[] )="_glUniform3fv"
Function glUniform3iv:Void( location, count, v[] )="_glUniform3iv"
Function glUniform4fv:Void( location, count, v#[] )="_glUniform4fv"
Function glUniform4iv:Void( location, count, v[] )="_glUniform4iv"
Function glUniformMatrix2fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix2fv"
Function glUniformMatrix3fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix3fv"
Function glUniformMatrix4fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix4fv"
Function glUseProgram:Void( program )
Function glValidateProgram:Void( program )
Function glVertexAttrib1f:Void( indx, x# )
Function glVertexAttrib2f:Void( indx, x#, y# )
Function glVertexAttrib3f:Void( indx, x#, y#, z# )
Function glVertexAttrib4f:Void( indx, x#, y#, z#, w# )
Function glVertexAttrib1fv:Void( indx, values#[] )="_glVertexAttrib1fv"
Function glVertexAttrib2fv:Void( indx, values#[] )="_glVertexAttrib2fv"
Function glVertexAttrib3fv:Void( indx, values#[] )="_glVertexAttrib3fv"
Function glVertexAttrib4fv:Void( indx, values#[] )="_glVertexAttrib4fv"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, data:DataBuffer )="_glVertexAttribPointer"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, offset )="_glVertexAttribPointer"
Function glViewport:Void( x, y, width, height )
'${END}

#Elseif TARGET="html5"

Function glTexImage2D:Void( target, level, internalformat, format, type, path:String )="_glTexImage2D"
Function glTexSubImage2D:Void( target, level, xoffset, yoffset, format, type, path:String )="_glTexSubImage2D"

'${HTML5_DECLS}
Function glActiveTexture:Void( texture )="gl.activeTexture"
Function glAttachShader:Void( program, shader )="gl.attachShader"
Function glBindAttribLocation:Void( program, index, name$ )="gl.bindAttribLocation"
Function glBindBuffer:Void( target, buffer )="_glBindBuffer"
Function glBindFramebuffer:Void( target, framebuffer )="_glBindFramebuffer"
Function glBindRenderbuffer:Void( target, renderbuffer )="_glBindRenderbuffer"
Function glBindTexture:Void( target, texture )="_glBindTexture"
Function glBlendColor:Void( red#, green#, blue#, alpha# )="gl.blendColor"
Function glBlendEquation:Void(  mode  )="gl.blendEquation"
Function glBlendEquationSeparate:Void( modeRGB, modeAlpha )="gl.blendEquationSeparate"
Function glBlendFunc:Void( sfactor, dfactor )="gl.blendFunc"
Function glBlendFuncSeparate:Void( srcRGB, dstRGB, srcAlpha, dstAlpha )="gl.blendFuncSeparate"
Function glBufferData:Void( target, size, data:DataBuffer, usage )="_glBufferData"
Function glBufferSubData:Void( target, offset, size, data:DataBuffer )="_glBufferSubData"
Function glCheckFramebufferStatus:Int( target )="gl.checkFramebufferStatus"
Function glClear:Void( mask )="gl.clear"
Function glClearColor:Void( red#, green#, blue#, alpha# )="gl.clearColor"
Function glClearDepthf:Void( depth# )="_glClearDepthf"
Function glClearStencil:Void( s )="gl.clearStencil"
Function glColorMask:Void( red?, green?, blue?, alpha? )="gl.colorMask"
Function glCompileShader:Void( shader )="gl.compileShader"
Function glCopyTexImage2D:Void( target, level, internalformat, x, y, width, height, border )="gl.copyTexImage2D"
Function glCopyTexSubImage2D:Void( target, level, xoffset, yoffset, x, y, width, height )="gl.copyTexSubImage2D"
Function glCreateBuffer:Int()="gl.createBuffer"
Function glCreateFramebuffer:Int()="gl.createFramebuffer"
Function glCreateRenderbuffer:Int()="gl.createRenderbuffer"
Function glCreateTexture:Int()="gl.createTexture"
Function glCreateProgram:Int()="gl.createProgram"
Function glCreateShader:Int( type )="gl.createShader"
Function glDeleteBuffer:Void( buffer )="gl.deleteBuffer"
Function glDeleteFramebuffer:Void( framebuffer )="gl.deleteFramebuffer"
Function glDeleteRenderbuffer:Void( renderBuffer )="gl.deleteRenderbuffer"
Function glDeleteTexture:Void( texture )="gl.deleteTexture"
Function glDeleteProgram:Void( program )="gl.deleteProgram"
Function glDeleteShader:Void( shader )="gl.deleteShader"
Function glCullFace:Void( mode )="gl.cullFace"
Function glDepthFunc:Void( func )="gl.depthFunc"
Function glDepthMask:Void( flag? )="gl.depthMask"
Function glDepthRangef:Void( zNear#, zFar# )="_glDepthRangef"
Function glDetachShader:Void( program, shader )="gl.detachShader"
Function glDisable:Void( cap )="gl.disable"
Function glDisableVertexAttribArray:Void( index )="gl.disableVertexAttribArray"
Function glDrawArrays:Void( mode, first, count )="gl.drawArrays"
Function glDrawElements:Void( mode, count, type, ptr:DataBuffer )="gl.drawElements"
Function glDrawElements:Void( mode, count, type, offset )="gl.drawElements"
Function glEnable:Void( cap )="gl.enable"
Function glEnableVertexAttribArray:Void( index )="gl.enableVertexAttribArray"
Function glFinish:Void()="gl.finish"
Function glFlush:Void()="gl.flush"
Function glFramebufferRenderbuffer:Void( target, attachment, renderbuffertarget, renderbuffer )="gl.framebufferRenderbuffer"
Function glFramebufferTexture2D:Void( target, attachment, textarget, texture, level )="gl.framebufferTexture2D"
Function glFrontFace:Void( mode )="gl.frontFace"
Function glGenerateMipmap:Void( target )="_glGenerateMipmap"
Function glGetActiveAttrib:Void( program, index, size[], type[], name$[] )="_glGetActiveAttrib"
Function glGetActiveUniform:Void( program, index, size[], type[], name$[] )="_glGetActiveUniform"
Function glGetAttachedShaders:Void( program, maxcount, count[], shaders[] )="_glGetAttachedShaders"
Function glGetAttribLocation:Int( program, name$ )="gl.getAttribLocation"
Function glGetBooleanv:Void( pname, params?[] )="gl.getBooleanv"
Function glGetBufferParameteriv:Void( target, pname, params[] )="_glGetBufferParameteriv"
Function glGetError:Int()="gl.getError"
Function glGetFloatv:Void( pname, params#[] )="_glGetFloatv"
Function glGetFramebufferAttachmentParameteriv:Void( target, attachment, pname, params[] )="_glGetFramebufferAttachmentParameteriv"
Function glGetIntegerv:Void( pname, params[] )="_glGetIntegerv"
Function glGetProgramiv:Void( program, pname, params[] )="_glGetProgramiv"
Function glGetProgramInfoLog:String( program )="gl.getProgramInfoLog"
Function glGetRenderbufferParameteriv:Void( target, pname, params[] )="_glGetRenderbufferParameteriv"
Function glGetShaderiv:Void( shader, pname, params[] )="_glGetShaderiv"
Function glGetShaderInfoLog:String( shader )="gl.getShaderInfoLog"
Function glGetShaderSource:String( shader )="gl.getShaderSource"
Function glGetString:String( name )="_glGetString"
Function glGetTexParameterfv:Void( target, pname, params#[] )="_glGetTexParameterfv"
Function glGetTexParameteriv:Void( target, pname, params[] )="_glGetTexParameteriv"
Function glGetUniformfv:Void( program, location, params#[] )="_glGetUniformfv"
Function glGetUniformiv:Void( program, location, params[] )="_glGetUniformiv"
Function glGetUniformLocation:Int( program, name$ )="_glGetUniformLocation"
Function glGetVertexAttribfv:Void( index, pname, params#[] )="_glGetVertexAttribfv"
Function glGetVertexAttribiv:Void( index, pname, params[] )="_glGetVertexAttribiv"
Function glHint:Void( target, mode )="gl.hint"
Function glIsBuffer:Bool( buffer )="gl.isBuffer"
Function glIsEnabled:Bool( cap )="gl.isEnabled"
Function glIsFramebuffer:Bool( framebuffer )="gl.isFramebuffer"
Function glIsProgram:Bool( program )="gl.isProgram"
Function glIsRenderbuffer:Bool( renderbuffer )="gl.isRenderbuffer"
Function glIsShader:Bool( shader )="gl.isShader"
Function glIsTexture:Bool( texture )="gl.isTexture"
Function glLineWidth:Void( width# )="gl.lineWidth"
Function glLinkProgram:Void( program )="gl.linkProgram"
Function glPixelStorei:Void( pname, param )="gl.pixelStorei"
Function glPolygonOffset:Void( factor#, units# )="gl.polygonOffset"
Function glReadPixels:Void( x, y, width, height, format, type, pixels:DataBuffer )="_glReadPixels"
Function glReleaseShaderCompiler:Void()="gl.releaseShaderCompiler"
Function glRenderbufferStorage:Void( target, internalformat, width, height )="gl.renderbufferStorage"
Function glSampleCoverage:Void( value#, invert? )="gl.sampleCoverage"
Function glScissor:Void( x, y, width, height )="gl.scissor"
Function glShaderSource:Void( shader, source$ )="gl.shaderSource"
Function glStencilFunc:Void( func, ref, mask )="gl.stencilFunc"
Function glStencilFuncSeparate:Void( face, func, ref, mask )="gl.stencilFuncSeparate"
Function glStencilMask:Void( mask )="gl.stencilMask"
Function glStencilMaskSeparate:Void( face, mask )="gl.stencilMaskSeparate"
Function glStencilOp:Void( fail, zfail, zpass )="gl.stencilOp"
Function glStencilOpSeparate:Void( face, fail, zfail, zpass )="gl.stencilOpSeparate"
Function glTexImage2D:Void( target, level, internalformat, width, height, border, format, type, pixels:DataBuffer )="_glTexImage2D2"
Function glTexSubImage2D:Void( target, level, xoffset, yoffset, width, height, format, type, pixels:DataBuffer )="_glTexSubImage2D2"
Function glTexParameterf:Void( target, pname, param# )="gl.texParameterf"
Function glTexParameteri:Void( target, pname, param )="gl.texParameteri"
Function glUniform1f:Void( location, x# )="gl.uniform1f"
Function glUniform1i:Void( location, x )="gl.uniform1i"
Function glUniform2f:Void( location, x#, y# )="gl.uniform2f"
Function glUniform2i:Void( location, x, y )="gl.uniform2i"
Function glUniform3f:Void( location, x#, y#, z# )="gl.uniform3f"
Function glUniform3i:Void( location, x, y, z )="gl.uniform3i"
Function glUniform4f:Void( location, x#, y#, z#, w# )="gl.uniform4f"
Function glUniform4i:Void( location, x, y, z, w )="gl.uniform4i"
Function glUniform1fv:Void( location, count, v#[] )="_glUniform1fv"
Function glUniform1iv:Void( location, count, v[] )="_glUniform1iv"
Function glUniform2fv:Void( location, count, v#[] )="_glUniform2fv"
Function glUniform2iv:Void( location, count, v[] )="_glUniform2iv"
Function glUniform3fv:Void( location, count, v#[] )="_glUniform3fv"
Function glUniform3iv:Void( location, count, v[] )="_glUniform3iv"
Function glUniform4fv:Void( location, count, v#[] )="_glUniform4fv"
Function glUniform4iv:Void( location, count, v[] )="_glUniform4iv"
Function glUniformMatrix2fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix2fv"
Function glUniformMatrix3fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix3fv"
Function glUniformMatrix4fv:Void( location, count, transpose?, value#[] )="_glUniformMatrix4fv"
Function glUseProgram:Void( program )="gl.useProgram"
Function glValidateProgram:Void( program )="gl.validateProgram"
Function glVertexAttrib1f:Void( indx, x# )="gl.vertexAttrib1f"
Function glVertexAttrib2f:Void( indx, x#, y# )="gl.vertexAttrib2f"
Function glVertexAttrib3f:Void( indx, x#, y#, z# )="gl.vertexAttrib3f"
Function glVertexAttrib4f:Void( indx, x#, y#, z#, w# )="gl.vertexAttrib4f"
Function glVertexAttrib1fv:Void( indx, values#[] )="gl.vertexAttrib1fv"
Function glVertexAttrib2fv:Void( indx, values#[] )="gl.vertexAttrib2fv"
Function glVertexAttrib3fv:Void( indx, values#[] )="gl.vertexAttrib3fv"
Function glVertexAttrib4fv:Void( indx, values#[] )="gl.vertexAttrib4fv"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, data:DataBuffer )="gl.vertexAttribPointer"
Function glVertexAttribPointer:Void( indx, size, type, normalized?, stride, offset )="gl.vertexAttribPointer"
Function glViewport:Void( x, y, width, height )="gl.viewport"
'${END}

#Endif

Public

#If TARGET="glfw" Or TARGET="ios" Or TARGET="android"

Function LoadImageData:DataBuffer( path:String,info:Int[]=[] )
	Local buf:=New DataBuffer
	If BBLoadImageData( buf,path,info ) Return buf
	Return Null
End

Function glTexImage2D:Void( target, level, internalformat, format, type, path:String )
	Local info:Int[2]
	Local buf:=LoadImageData( path,info )
	If buf glTexImage2D target,level,internalformat,info[0],info[1],0,format,type,buf
End

Function glTexSubImage2D:Void( target, level, xoffset, yoffset, format, type, path:String )
	Local info:Int[2]
	Local buf:=LoadImageData( path,info )
	If buf glTexSubImage2D target,level,xoffset,yoffset,info[0],info[1],format,type,buf
End

#Endif
