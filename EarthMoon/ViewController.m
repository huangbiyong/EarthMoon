//
//  ViewController.m
//  EarthMoon
//
//  Created by chhu02 on 2019/6/20.
//  Copyright © 2019 chase. All rights reserved.
//

#import "ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "sphere.h"


//场景地球轴倾斜度
static const GLfloat SceneEarthAxialTiltDeg = 23.5f;
//月球轨道日数
static const GLfloat SceneDaysPerMoonOrbit = 28.0f;
//半径
static const GLfloat SceneMoonRadiusFractionOfEarth = 0.25;
//月球距离地球的距离
static const GLfloat SceneMoonDistanceFromEarth = 1.5f;

@interface ViewController ()

@property(nonatomic,strong)EAGLContext *mContext;

//顶点positionBuffer
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertexPositionBuffer;

//顶点NormalBuffer
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertexNormalBuffer;

//顶点TextureCoordBuffer
@property(nonatomic,strong)AGLKVertexAttribArrayBuffer *vertextTextureCoordBuffer;

//光照、纹理
@property(nonatomic,strong)GLKBaseEffect *baseEffect;

//不可变纹理对象数据,地球纹理对象
@property(nonatomic,strong)GLKTextureInfo *earchTextureInfo;

//月亮纹理对象
@property(nonatomic,strong)GLKTextureInfo *moomTextureInfo;

//模型视图矩阵
//GLKMatrixStackRef CFType 允许一个4*4 矩阵堆栈
@property(nonatomic,assign)GLKMatrixStackRef modelViewMatrixStack;

//地球的旋转角度
@property(nonatomic,assign)GLfloat earthRotationAngleDegress;
//月亮旋转的角度
@property(nonatomic,assign)GLfloat moonRotationAngleDegress;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.新建OpenGL ES 上下文
    [self setupContext];
    
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
    
    //3.创建GLKBaseEffect 只能有3个光照、2个纹理
    [self setupBaseEffect];
    
    //6.设置清屏颜色
    GLKVector4 colorVector4 = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
    [self setClearColor:colorVector4];
    
    //7.顶点数组
    [self bufferData];
}

- (void)setupContext {
    
    //1.新建OpenGL ES 上下文
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //2.获取GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
}

- (void)setupBaseEffect {
    
    self.baseEffect = [[GLKBaseEffect alloc]init];
    
    //配置baseEffect光照信息
    [self configureLight];
    
    //获取屏幕纵横比
    GLfloat aspectRatio = self.view.bounds.size.width / self.view.bounds.size.height;
    
    //4.创建投影矩阵 -> 透视投影
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeFrustum(-1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0, 2.0, 120.0);
    
    //5.设置模型矩形 -5.0f表示往屏幕内移动-5.0f距离
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
}


-(void)bufferData
{
    //1、GLKMatrixStackCreate()创建一个新的空矩阵
    self.modelViewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
    
    //2、为将要缓存区数据开辟空间
    //sphereVerts 在sphere.h文件中存在
    /*
     参数1：数据大小 3个GLFloat类型，x,y,z
     参数2：有多少个数据，count
     参数3：数据大小
     参数4：用途 GL_STATIC_DRAW，
     */
    //顶点数据缓存，顶点数据从sphere.h文件的sphereVerts数组中获取顶点数据x,y,z
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:(3 * sizeof(GLfloat)) numberOfVertices:sizeof(sphereVerts)/(3 * sizeof(GLfloat)) bytes:sphereVerts usage:GL_STATIC_DRAW];
    
    //法线，光照坐标 sphereNormals数组 x,y,z
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:(3 * sizeof(GLfloat)) numberOfVertices:sizeof(sphereNormals)/(3 * sizeof(GLfloat)) bytes:sphereNormals usage:GL_STATIC_DRAW];
    
    //纹理坐标 sphereTexCoords数组 x,y
    self.vertextTextureCoordBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:(2 * sizeof(GLfloat)) numberOfVertices:sizeof(sphereTexCoords)/ (2 * sizeof(GLfloat)) bytes:sphereTexCoords usage:GL_STATIC_DRAW];
    
    
    //3.获取地球纹理
    CGImageRef earthImageRef = [UIImage imageNamed:@"Earth512x256.jpg"].CGImage;
    
    //控制图像加载方式的选项
    NSDictionary *earthOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil];
    
    //将纹理图片加载到纹理数据对象earchTextureInfo中
    /*
     参数1:加载的纹理图片
     参数2:控制图像加载的方式的选项-字典
     参数3:错误信息
     */
    self.earchTextureInfo = [GLKTextureLoader textureWithCGImage:earthImageRef options:earthOptions error:NULL];
    
    //4.获取月亮纹理
    CGImageRef moonImageRef = [UIImage imageNamed:@"Moon256x128"].CGImage;
    NSDictionary *moonOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil];
    
    self.moomTextureInfo = [GLKTextureLoader textureWithCGImage:moonImageRef options:moonOptions error:NULL];
    
    //矩阵堆
    //用所提供的矩阵替换最顶层矩阵,将self.baseEffect.transform.modelviewMatrix,替换self.modelViewMatrixStack
    GLKMatrixStackLoadMatrix4(self.modelViewMatrixStack, self.baseEffect.transform.modelviewMatrix);
    
    //初始化在轨道上月球位置
    self.moonRotationAngleDegress = -20.0f;
    
    
}

-(void)setClearColor:(GLKVector4)clearColorRGBA
{
    glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}

-(void)configureLight
{
    
    //1.是否开启light0光照
    self.baseEffect.light0.enabled = GL_TRUE;
    

    //2.设置漫射光颜色
    self.baseEffect.light0.diffuseColor = GLKVector4Make(
                                                         1.0f,//Red
                                                         1.0f,//Green
                                                         1.0f,//Blue
                                                         0.0f);//w
    self.baseEffect.light0.position = GLKVector4Make(
                                                     1.0f, //x
                                                     0.0f, //y
                                                     0.8f, //z
                                                     0.0f);//w
    
    //光的环境部分
    self.baseEffect.light0.ambientColor = GLKVector4Make(
                                                         0.2f,//Red
                                                         0.2f,//Green
                                                         0.2f,//Blue
                                                         1.0f);//Alpha
    
}

#pragma mark - drawRect
//渲染场景
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //设置清屏颜色
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    
    //清空颜色缓存区和深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //地球旋转角度
    _earthRotationAngleDegress += 360.0f/60.0f / SceneDaysPerMoonOrbit * 2;
    //月球旋转角度
    _moonRotationAngleDegress += (360.0f/60.0f)/SceneDaysPerMoonOrbit * 2;
    
    //2、准备绘制
    [self.vertexPositionBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.vertexNormalBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.vertextTextureCoordBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:0 shouldEnable:YES];
    
    //3.开始绘制
    [self drawEarth];
    [self drawMoon];
    
}


-(void)drawEarth
{
    //获取纹理的name、target
    self.baseEffect.texture2d0.name = self.earchTextureInfo.name;
    self.baseEffect.texture2d0.target = self.earchTextureInfo.target;
    
    
    //将当前的modelViewMatrixStack 压栈
    GLKMatrixStackPush(self.modelViewMatrixStack);
    
    //在指定的轴上旋转最上面的矩阵。
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(SceneEarthAxialTiltDeg), 1.0f, 0.0f, 0.0f);
    GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(_earthRotationAngleDegress), 0.0f, 1.0f, 0.0f);
   
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
    //准备绘制
    [self.baseEffect prepareToDraw];
    

    // 设置顶点
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    
    //绘制完毕，则出栈
    GLKMatrixStackPop(self.modelViewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
    
}

-(void)drawMoon {
    // 绘制6个月球
    for (NSInteger i=0; i<6; i++) {
        
        //获取纹理的name、target
        self.baseEffect.texture2d0.name = self.moomTextureInfo.name;
        self.baseEffect.texture2d0.target = self.moomTextureInfo.target;
        
        //压栈
        GLKMatrixStackPush(self.modelViewMatrixStack);
        
        
        //围绕Y轴旋转moonRotationAngleDegress角度
        //自转
        GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(self.moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);
        
        // 设置不同月球的间距
        float xDistance = SceneMoonDistanceFromEarth * cos(i * GLKMathDegreesToRadians(60));
        float zDistance = SceneMoonDistanceFromEarth * sin(i * GLKMathDegreesToRadians(60));
        
        //平移 -月球距离地球的距离
        GLKMatrixStackTranslate(self.modelViewMatrixStack, xDistance, 0.0f, zDistance);
        
        //缩放，把月球缩放
        GLKMatrixStackScale(self.modelViewMatrixStack, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth);
        
        
        self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
        
        [self.baseEffect prepareToDraw];
        
        [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
        
        GLKMatrixStackPop(self.modelViewMatrixStack);
    }
    
    self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
}



@end
