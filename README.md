# Opengl es 实现六个月球绕地球旋转

![](https://upload-images.jianshu.io/upload_images/8533386-ad5d48e56ec2edcf.gif?imageMogr2/auto-orient/strip)

#### 1. 配置环境
- 引入#import <GLKit/GLKit.h>；
- 将视图控制器设置继承GLKViewController；
```
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

@end
```
---
#### 2. 编程代码
```
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

//7.顶点数组 从cpu 复制data到gpu
[self bufferData];
}
```

这一部分主要初始化pengl es的，创建数组缓存区、顶点缓存区、法线缓冲区、纹理缓存区，并将相应的数据从CPU复制到GPU。创建一个GLKBaseEffect对象，用来绘制几何图形。只需要复制 **一次** 就可以。

由于继承了GLKViewController，所以屏幕在每一帧刷新时，会自动调用GLKViewDelegate代理方法；
> - (void)glkView:(GLKView *)view drawInRect:(CGRect)rect;

我们的绘制操作、清屏操作等，都在这里执行；

```
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
```

#### 3. 绘制几何图形
- 设置清屏颜色，并清空渲染缓存区
```
//设置清屏颜色
glClearColor(0.3f, 0.3f, 0.3f, 1.0f);

//清空颜色缓存区和深度缓存区
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
```
- 使用 **GLKTextureInfo** 对象，来加载纹理图片；
- 使用 **AGLKVertexAttribArrayBuffer** 来设置如何读取数据；
```
[self.vertexPositionBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
[self.vertexNormalBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
[self.vertextTextureCoordBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:0 shouldEnable:YES];
```
- 由于使用累两个不同的纹理，和几何图形，所以需要使用到 **GLKMatrixStack** 对模型试图坐标进行出栈或入栈操作；不然会导致模型坐标混乱，显示不出效果；
```
// 绘制地球
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

// 绘制6个月球
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
```
