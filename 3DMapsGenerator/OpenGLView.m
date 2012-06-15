//
//  OpenGLView.m
//  3DMapsGenerator
//
//  Created by Antonio Martinez on 6/15/12.
//  Copyright (c) 2012 AMG. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

@interface OpenGLView (){
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    float _currentRotation;
    GLuint _depthRenderBuffer;
    
}

@end

@implementation OpenGLView

@synthesize zoom;

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

#define TEX_COORD_MAX   1

const Vertex Vertices[] = {
    // Front
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {1, 0, 0, 1}},
    {{-1, 1, 0}, {1, 0, 0, 1}},
    {{-1, -1, 0}, {1, 0, 0, 1}},
    // Back
    {{1, 1, -2}, {1, 0, 1, 1}},
    {{-1, -1, -2}, {1, 0, 1, 1}},
    {{1, -1, -2}, {1, 0, 1, 1}},
    {{-1, 1, -2}, {1, 0, 0, 1}},
    // Left
    {{-1, -1, 0}, {1, 0, 0, 1}}, 
    {{-1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, -2}, {0, 0, 1, 1}},
    {{-1, -1, -2}, {0, 0, 0, 1}},
    // Right
    {{1, -1, -2}, {0, 1, 0, 1}},
    {{1, 1, -2}, {0, 1, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{1, -1, 0}, {0, 0, 0, 1}},
    // Top
    {{1, 1, 0}, {1, 1, 0, 1}},
    {{1, 1, -2}, {1, 1, 0, 1}},
    {{-1, 1, -2}, {1, 1, 0, 1}},
    {{-1, 1, 0}, {1, 1, 0, 1}},
    // Bottom
    {{1, -1, -2}, {1, 0, 0, 1}},
    {{1, -1, 0}, {0, 1, 0, 1}},
    {{-1, -1, 0}, {0, 0, 1, 1}}, 
    {{-1, -1, -2}, {0, 0, 0, 1}}
};

const Vertex Vertices2[] = {
    // Front
    {{1, -1, 0}, {0, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}},
    // Back
    {{3, 3, -2}, {0, 0, 0, 1}},
    {{-3, -3, -2}, {0, 0, 0, 1}},
    {{3, -3, -2}, {0, 0, 0, 1}},
    {{-3, 3, -2}, {0, 0, 0, 1}},
    // Left
    {{-1, -1, 0}, {0, 0, 0, 1}}, 
    {{-1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, -2}, {0, 0, 1, 1}},
    {{-1, -1, -2}, {0, 0, 0, 1}},
    // Right
    {{1, -1, -2}, {0, 0, 0, 1}},
    {{1, 1, -2}, {0, 1, 0, 1}},
    {{1, 1, 0}, {0, 0, 1, 1}},
    {{1, -1, 0}, {0, 0, 0, 1}},
    // Top
    {{1, 1, 0}, {0, 0, 0, 1}},
    {{1, 1, -2}, {0, 1, 0, 1}},
    {{-1, 1, -2}, {0, 0, 1, 1}},
    {{-1, 1, 0}, {0, 0, 0, 1}},
    // Bottom
    {{1, -1, -2}, {0, 0, 0, 1}},
    {{1, -1, 0}, {0, 1, 0, 1}},
    {{-1, -1, 0}, {0, 0, 1, 1}}, 
    {{-1, -1, -2}, {0, 0, 0, 1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 5, 6,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};


- (void)dealloc
{
    [_context release];
    _context = nil;
    [super dealloc];
}

//- (void)setupVBOs {
//    
//    GLuint vertexBuffer;
//    glGenBuffers(1, &vertexBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
//
//    
//    GLuint indexBuffer;
//    glGenBuffers(1, &indexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
//    
//}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        zoom = 3;
        
        [self setupLayer];        
        [self setupContext];  
        [self setupDepthBuffer];
        [self setupRenderBuffer]; 
        [self setupFrameBuffer]; 
        [self compileShaders];
//        [self setupVBOs];
        [self setupDisplayLink];
    }
    return self;
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName 
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath 
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);    
    
    const char * shaderStringUTF8 = [shaderString UTF8String];    
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileShaders {
    
    GLuint vertexShader = [self compileShader:@"SimpleVertex" 
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" 
                                       withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
}

#pragma mark Init OpenGL

/** 
 * Set up the EAGL Context
 */
- (void)setupContext {   
    EAGLRenderingAPI apiRendering = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:apiRendering];
    if (!_context) {
        NSLog(@"Failed to init OpenGL ES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL ES context");
        exit(1);
    }
}

/**
 * Create the render buffer. It will store the rendered images to present to the screen
 */
- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);        
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];    
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);    
}



/**
 * Create the frame buffer. It will contain all the buffers, including render buffer
 */
- (void)setupFrameBuffer {    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                              GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}


/**
 * Render the view
 */
- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-1 andRight:1 andBottom:-h andTop:h andNear:1 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(0, 0, -7)];
//    _currentRotation += displayLink.duration * 90;
//    [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), 
                   GL_UNSIGNED_BYTE, 0);
    
    GLuint vertexBuffer2;
    glGenBuffers(1, &vertexBuffer2);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices2), Vertices2, GL_STATIC_DRAW);
    
    GLuint indexBuffer2;
    glGenBuffers(1, &indexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer2);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
//    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), 
                   GL_UNSIGNED_BYTE, 0);
    
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark Layer methods



//Override the layer to make it CAEAGLLayer
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//Set it up to opaque (default is transparent)
- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
