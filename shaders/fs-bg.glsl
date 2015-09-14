uniform float time;

uniform float parameter1;
uniform float parameter2;
uniform float parameter3;
uniform float parameter4;
uniform float parameter5;
uniform float parameter6;

uniform vec3 lightColor1;
uniform vec3 lightColor2;

uniform float filledness;
uniform float completed;

varying vec3 vPos;
varying vec3 vCam;
varying vec3 vNorm;

varying vec3 vLight1;
varying vec3 vLight2;


varying vec2 vUv;



const float MAX_TRACE_DISTANCE = 5.;           // max trace distance
const float INTERSECTION_PRECISION = 0.1;        // precision of the intersection
const int NUM_OF_TRACE_STEPS = 20;

vec3 sunPos; 



vec3 hsv(float h, float s, float v){
        return mix( vec3( 1.0 ), clamp(( abs( fract(h + vec3( 3.0, 2.0, 1.0 ) / 3.0 )
                   * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
      }



vec2 opU( vec2 d1, vec2 d2 )
{
    return  d1.x < d2.x ? d1 : d2 ;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}


float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}


float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float opRepSphere( vec3 p, vec3 c , float r)
{
    vec3 q = mod(p,c)-0.5*c;
    return sdSphere( q  , r );
}


float opRepBox( vec3 p, vec3 c , float r)
{
    vec3 q = mod(p,c)-0.5*c;
    return sdBox( q  ,vec3( r ));
}

vec2 smoothU( vec2 d1, vec2 d2, float k)
{
    float a = d1.x;
    float b = d2.x;
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return vec2( mix(b, a, h) - k*h*(1.0-h), mix(d2.y, d1.y, pow(h, 2.0)));
}



// Using SDF from IQ's two tweet shadertoy : 
// https://www.shadertoy.com/view/MsfGzM
float sdBlob( vec3 p ){

  return length(
    .05 * cos( 9. * (sin( parameter1 )+ 1.) * p.y * p.x )
    + cos(p) * (sin( parameter2 ) * .01 + 1.) 
    -.1 * cos( 9. * ( p.z + .3 * (sin(parameter3) + 1.)   * p.x - p.y * (sin( parameter4 )+ 1.)   ) ) )
    -1.; 

}


float sphereField( vec3 p ){

  float fieldSize = 2. - filledness; //abs( sin( pa) ) * 1.;
  return opRepSphere( p , vec3(fieldSize ), .04 + parameter4 * .05 );

}


float cubeField( vec3 p ){

  float fieldSize = 1.  + abs( sin( parameter5) ) * 1.;
  return opRepBox( p , vec3(fieldSize ), .3 + parameter4 * .05  );

}

float sdBlob2( vec3 p ){
 
  vec3 pos = p;

  return length( p ) - .2 + .3 * .2 * sin( parameter4 )*sin(300.0 * sin(parameter1 ) *pos.x * sin( length(pos) ))*sin(200.0*sin( parameter2 ) *pos.y )*sin(50.0 * sin( parameter3 * 4. )*pos.z);

}


mat4 rotateX(float angle){
    
  angle = -angle/180.0*3.1415926536;
    float c = cos(angle);
    float s = sin(angle);
  return mat4(1.0, 0.0, 0.0, 0.0, 0.0, c, -s, 0.0, 0.0, s, c, 0.0, 0.0, 0.0, 0.0, 1.0);
    
}

mat4 rotateY(float angle){
    
  angle = -angle/180.0*3.1415926536;
    float c = cos(angle);
    float s = sin(angle);
  return mat4(c, 0.0, s, 0.0, 0.0, 1.0, 0.0, 0.0, -s, 0.0, c, 0.0, 0.0, 0.0, 0.0, 1.0);
    
}

mat4 rotateZ(float angle){
    
  angle = -angle/180.0*3.1415926536;
    float c = cos(angle);
    float s = sin(angle);
  return mat4(c, -s, 0.0, 0.0, s, c, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
    
}

mat4 translate(vec3 t){
    
  return mat4(1.0, 0.0, 0.0, -t.x, 0.0, 1.0, 0.0, -t.y, 0.0, 0.0, 1.0, -t.z, 0.0, 0.0, 0.0, 1.0);
    
}


vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float mandala( vec3 pos ){


  vec4 p = vec4( pos.xyz , 1. );

//vec3 nP = vec3( pos.x , mod( pos.y , .8 ) , pos.z )


  vec2 res = vec2(10000.,10000.);

  for( int i = 0; i < 8; i++ ){
    float degrees = (float( i ) / 8.) * 360.;

    mat4 m = rotateX(degrees) * translate(vec3(0.0,  completed * 2. , 0.0)) ;

    p = vec4( pos.xyz , 1. ) * m; 
    //p = vec4( p.x , mod( p.y , 1.) , p.z , 1.);

    res = smoothU( res , vec2( length(p.xyz) - .4 , 1. ) , .2);



  }

 // degrees = mod( degrees , 3.14159 / 10.2 );

 // vec3 nP = mod( p + vec3( .3 , .3 , .3 ), vec3( 1. , 1. , 1.) ); //vec3( sin( degrees ) * radius , cos( degrees ) * radius , 0. );//tan( degrees ) * radius;

 
 //vec3 nP = vec3( p.x , mod( p.y , 1. ) , mod( p.z, .5 ) );

  return res.x; //length(  nP ) - .3;


}

//--------------------------------
// Modelling 
//--------------------------------
vec2 map( vec3 pos ){  
   


   //// vec2 res = vec2( opRepSphere( pos , vec3( repSize ) , radius ) , 1. );
    vec2 res = vec2( sdSphere( pos - sunPos, .6) , 1. );
    vec2 res2 = vec2( sdSphere( pos + vec3( 0., 20. , 0. ), 18. ) , 2. );

    res = smoothU( res , res2 , .2 );

    //res2 = vec2( mandala( pos - sunPos ) , 1. );

    res = smoothU( res , res2 , .2 );


    vec2 res3 =  vec2( sphereField( pos ) , 2. );


    return res3 * completed + res * (1. - completed);
    
}


vec2 calcIntersection( in vec3 ro, in vec3 rd ){

    
    float h =  INTERSECTION_PRECISION*2.0;
    float t = 0.0;
    float res = -1.0;
    float id = -1.;
    
    for( int i=0; i< NUM_OF_TRACE_STEPS ; i++ ){
        
        if( h < INTERSECTION_PRECISION || t > MAX_TRACE_DISTANCE ) break;
      vec2 m = map( ro+rd*t );
        h = m.x;
        t += h;
        id = m.y;
        
    }

    if( t < MAX_TRACE_DISTANCE ) res = t;
    if( t > MAX_TRACE_DISTANCE ) id =-1.0;
    
    return vec2( res , id );
    
}




// Calculates the normal by taking a very small distance,
// remapping the function, and getting normal for that
vec3 calcNormal( in vec3 pos ){
    
  vec3 eps = vec3( 0.001, 0.0, 0.0 );
  vec3 nor = vec3(
      map(pos+eps.xyy).x - map(pos-eps.xyy).x,
      map(pos+eps.yxy).x - map(pos-eps.yxy).x,
      map(pos+eps.yyx).x - map(pos-eps.yyx).x );

  return normalize(nor);
}


float calcAO( in vec3 pos, in vec3 nor )
{
  float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.612*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.5;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}


vec2 doLight( vec3 lightPos , vec3 pos , vec3 norm , vec3 eyeDir ){

  vec3 lightDir = normalize( lightPos - pos );
  vec3 reflDir  = reflect( lightDir , norm );


  float lamb = max( 0. , dot( lightDir , norm   ) );
  float spec = max( 0. , dot( reflDir  , eyeDir ) );

  return vec2( lamb , spec );

}


vec3 doBoxShading( vec2 l1 , vec2 l2 , vec3 ro ){

  vec3 col = vec3( 0. );

  float fillednessVal = (( ro.y + 1.5 )  / 3. ) * filledness;

  vec3 a = vec3( .5 );
  vec3 b = vec3( .5 );
  vec3 c = vec3( 2. , 1.,  0. );
  vec3 d = vec3( .5 , .2 , .25 );
  float spec = pow( l1.y , 40. );
  col +=  palette( l1.x + spec * 1., a , b , c ,d ) * (  spec ) * .5;

  a = vec3( .5 );
  b = vec3( .5 );
  c = vec3( 1. , 1.,  0. );
  d = vec3( .8 , .9 , .3 );
  spec = pow( l2.y , 40. );
  col +=  palette( l2.x + spec * 1., a , b , c ,d ) * (  spec ) * .5;


  float edgeSize = .05  * (1. - completed ) + .01;
  if( vUv.x < edgeSize || vUv.x > 1. - edgeSize || vUv.y < edgeSize || vUv.y > 1. - edgeSize ){
    col += vec3( .3 , .3 , .3 );
  }

  return col;

}

vec3 doBackgroundShading( vec2 l1 , vec2 l2 , vec3 ro ){

  float fillednessVal = ( ro.y + 1.5 ) / 3. * filledness * ( 1. + completed );


  vec3 a = vec3( .5 );
  vec3 b = vec3( .5 );
  vec3 c = vec3( 1. , 1.,  0. );
  vec3 d = vec3( .8 , .9 , .3 );

  vec3 p =  palette( fillednessVal / 2., a , b , c ,d );

  vec3 col = p  * filledness* ( 1. + completed * .4 ) * .5; //* ( 1. - completed );

  return col;

}


vec3 doRayShading( vec2 l1 , vec2 l2  , vec3 norm , vec3 ro ){

  vec3 col = vec3( 0. );

  vec3 a = vec3( .5 );
  vec3 b = vec3( .5 );
  vec3 c = vec3( 2. , 1.,  0. );
  vec3 d = vec3( .5 , .2 , .25 );
  float spec = pow( l1.y , 10. );
  col +=  palette( l1.x , a , b , c ,d ) * ( l1.x + spec );

  a = vec3( .5 );
  b = vec3( .5 );
  c = vec3( 1. , 1.,  0. );
  d = vec3( .8 , .9 , .3 );
  spec = pow( l2.y , 10. );
  col +=  palette( l2.x , a , b , c ,d ) * ( l2.x  + spec );

  //col += norm * .5 + .5;

  col += doBackgroundShading( l1 , l2 , ro ); //}

  return col;
}




void main(){

  sunPos = vec3( 0. , filledness * 2. - 3. + completed * 5. , -3.6 );

  vec3 ro = vPos;
  vec3 rd = normalize( vPos - vCam );

  vec2 res = calcIntersection( ro , rd );


  vec2 light1 = doLight( vLight1 , ro , vNorm , rd );
  vec2 light2 = doLight( vLight2 , ro , vNorm , rd );



  float fillednessVal = (( ro.y + 1.5 )  / 3. ) * filledness;
  vec3 col = vec3( 0. , 0. , 0. );

  col += doBoxShading( light1 , light2 , ro );

  if( res.y > .5 ){

    vec3 pos = ro + rd * res.x;
    vec3 norm = calcNormal( pos );


    light1 = doLight( vLight1 , pos , norm , rd );
    light2 = doLight( vLight2 , pos , norm , rd );

   // col += norm * .5 + .5;
    col += doRayShading( light1 , light2 , norm , ro );

  }else{

    col += doBackgroundShading( light1 , light2 , ro );

  }


  //vec3 col = vec3( 2. - length( texture2D( t_iri , vUv * 4. - vec2( 1.5 ) ) ));

  //vec3 col = vec3( hit );

  //col = vCam * .5 + .5;


  //gl_FragColor = vec4(vec3( length(col)) , 1. );
  gl_FragColor = vec4( col , 1. );

  //gl_FragColor = vec4( 1. );

}
