
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


mat4 palette1;
mat4 palette2;
mat4 palette3;


// Branch Code stolen from : https://www.shadertoy.com/view/ltlSRl
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

const float MAX_TRACE_DISTANCE = 5.0;             // max trace distance
const float INTERSECTION_PRECISION = 0.01;        // precision of the intersection
const int NUM_OF_TRACE_STEPS = 15;
const float PI = 3.14159;

vec3 hsv(float h, float s, float v){
        return mix( vec3( 1.0 ), clamp(( abs( fract(h + vec3( 3.0, 2.0, 1.0 ) / 3.0 )
                   * 6.0 - 3.0 ) - 1.0 ), 0.0, 1.0 ), s ) * v;
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


float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}


vec2 smoothU( vec2 d1, vec2 d2, float k)
{
    float a = d1.x;
    float b = d2.x;
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return vec2( mix(b, a, h) - k*h*(1.0-h), mix(d2.y, d1.y, pow(h, 2.0)));
}



//--------------------------------
// Modelling 
//--------------------------------
vec2 map( vec3 pos ){  
    
    
    float branchSize = .3;
    float reductionFactor = .7 +  .1 * sin( time * .73 );
    float trunkSize = .2 +  .1 * sin( time * .27 );
    float bs = branchSize;
    float rot = 40. + 10. * sin( time * .6 );
    
    pos += vec3( 0. , branchSize , 0. );

   
    vec4 p = vec4( pos , 1. );
    mat4 m;
    
    //vec2 res = vec2( length( pos + vec3( 0. , .5, 0.) ) - .5, 0.0 );
  
    //vec2 res = smoothU( res ,vec2(sdCappedCylinder( p.xyz , vec2( trunkSize * bs , bs )),1.);

    //vec2 res = vec2( sdCappedCylinder( p.xyz , vec2( trunkSize * bs , bs )),1.);
    vec2 res = vec2( length(p.xyz + vec3( 0., 6. , 0. )) - 6. , 1. );

      //  res = smoothU( res, vec2( length( p.xyz - vLight1 + vec3( 0., .3 , 0. )) - .3 ,10. ) , .1);
      //  res = smoothU( res, vec2( length( p.xyz - vLight2+ vec3( 0., .3 , 0. )) - .3 ,100. ), .1);

    res = smoothU( res , vec2(sdCappedCylinder( p.xyz , vec2( trunkSize * bs , bs )),1.), .1);
    
    for( int i = 0; i < 4; i ++ ){
        bs *= reductionFactor;

        m = translate(vec3(0.0, bs*2. , 0.0)) * rotateY(rot) * rotateX(rot);    
        p.x = abs(p.x) - bs / 2.;
        p.z = abs(p.z) - bs / 2.;   
        p = p * m; 

        res = smoothU( res , vec2( sdCappedCylinder( p.xyz , vec2( trunkSize * bs , bs )),1.) , .1);
    }



    return res;
    
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




vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 doPalette( in float val , in mat4 pType ){
  return palette( val ,  pType[0].xyz , pType[1].xyz , pType[2].xyz , pType[3].xyz );
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

  float spec = pow( l1.y , 40. );
  col +=  doPalette( l1.x , palette1 ) * ( spec ) * .5;

  spec = pow( l2.y , 40. );
  col +=  doPalette( l2.x , palette2 ) * ( spec ) * .5;


  float edgeSize = .05  * (1. - completed ) + .01;
  if( vUv.x < edgeSize || vUv.x > 1. - edgeSize || vUv.y < edgeSize || vUv.y > 1. - edgeSize ){
    col += vec3( .3 , .3 , .3 );
  }

  return col;

}

vec3 doBackgroundShading( vec2 l1 , vec2 l2 , vec3 ro ){

  float fillednessVal = ( ro.y + 1.5 ) / 3. * filledness * ( 1. + completed );

  vec3 p =  doPalette( fillednessVal / 2. , palette3 ); 

  vec3 col = p  * filledness* ( 1. - completed * 1. ) * .5; //* ( 1. - completed );

  return col;

}


vec3 doRayShading( vec2 l1 , vec2 l2  , vec3 norm , vec3 ro ){

  vec3 col = vec3( 0. );

  float spec = pow( l1.y , 10. );
  col +=  doPalette( l1.x , palette1 ) * ( l1.x  + spec );

  spec = pow( l2.y , 10. );
  col +=  doPalette( l2.x , palette2 ) * ( l2.x  + spec );

  col += doBackgroundShading( l1 , l2 , ro ); //}

  return col;
}



void main(){

  //sunPos = vec3( 0. , filledness * 2. - 3. + completed * 5. , -3.6 );


  /*palette1 = mat4( .5 , .5 , .5 , 0. 
                 , .5 , .5 , .5 , 0.
                 , 1. , 1. , 1. , 0.
                 , .3 , .2 , .2 , 0.
                 );

  palette2 = mat4( .5 , .5 , .5 , 0. 
                 , .5 , .5 , .5 , 0.
                 , 1. , 1. , 0. , 0.
                 , .8 , .9 , .3 , 0.
                 );


  palette3 = mat4( .5 , .5 , .5 , 0. 
                 , .5 , .5 , .5 , 0.
                 , 2. , 1. , 0. , 0.
                 , .5 , .2 , .25 , 0.
                 );*/


  palette1 = mat4( .5  * ( 1. + sin( time * .5 ) * .3 ) , .5 * ( 1. + sin( time * .5 ) * .3 )  , .5 * ( 1. + sin( time * .5 ) * .3 )  , 0. 
                 , .5  * ( 1. + sin( time * .8 ) * .3 ) , .5 * ( 1. + sin( time * .3 ) * .3 )  , .5 * ( 1. + sin( time * .19 ) * .3 )  , 0.
                 , 1.  * ( 1. + sin( time * .2 ) * .3 ) , 1. * ( 1. + sin( time * .7 ) * .3 )  , 1. * ( 1. + sin( time * .4 ) * .3 )  , 0.
                 , .3  * ( 1. + sin( time * .1 ) * .3 ) , .2 * ( 1. + sin( time * .9 ) * .3 )  , .2 * ( 1. + sin( time * 1.5 ) * .3 )  , 0.
                 );

  palette2 = mat4( .5 * ( 1. + sin( time * .56 ) * .3 )  , .5 * ( 1. + sin( time * .225 ) * .3 )  , .5  * ( 1. + sin( time * .111 ) * .3 ) , 0. 
                 , .5 * ( 1. + sin( time * 1.5 ) * .3 )  , .5 * ( 1. + sin( time * .2 ) * .3 )  , .5  * ( 1. + sin( time * .3 ) * .3 ) , 0.
                 , 1. * ( 1. + sin( time * .73 ) * .3 )  , 1. * ( 1. + sin( time * .15 ) * .3 )  , 0.  * ( 1. + sin( time * .74 ) * .3 ) , 0.
                 , .8 * ( 1. + sin( time * 1.5 ) * .3 )  , .9 * ( 1. + sin( time * .35 ) * .3 )  , .3  * ( 1. + sin( time * .9 ) * .3 ) , 0.
                 );


  palette3 = mat4( .5  * ( 1. + sin( time * .86 ) * .3 )  , .5 * ( 1. + sin( time * .51 ) * .3 )  , .5  * ( 1. + sin( time * .2 ) * .3 ) , 0. 
                 , .5  * ( 1. + sin( time * 1. ) * .3 )  , .5 * ( 1. + sin( time * .76 ) * .3 )  , .5  * ( 1. + sin( time * 1.5 ) * .3 ) , 0.
                 , 2.  * ( 1. + sin( time * .72 ) * .3 )  , 1. * ( 1. + sin( time * .21 ) * .3 )  , 0.  * ( 1. + sin( time * .632 ) * .3 ) , 0.
                 , .5  * ( 1. + sin( time * .11 ) * .3 )  , .2 * ( 1. + sin( time * .06 ) * .3 )  , .25 * ( 1. + sin( time * .755 ) * .3 )  , 0.
                 );


  vec3 ro = vPos;
  vec3 rd = normalize( vPos - vCam );

  vec2 res = calcIntersection( ro , rd );


  vec2 light1 = doLight( vLight1 , ro , vNorm , rd );
  vec2 light2 = doLight( vLight2 , ro , vNorm , rd );

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


  gl_FragColor = vec4( col , 1. );


}