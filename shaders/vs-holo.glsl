
uniform mat4 iModelMat;
uniform vec3 lightPosition1;
uniform vec3 lightPosition2;

varying vec3 vPos;
varying vec3 vLight1;
varying vec3 vLight2;
varying vec3 vNorm;
varying vec3 vCam;

varying vec2 vUv;


void main(){

  vUv = uv;

  vPos = position;
  vNorm = normal;

  vCam   = ( iModelMat * vec4( cameraPosition , 1. ) ).xyz;
  vLight1 = ( iModelMat * vec4( lightPosition1 , 1. ) ).xyz;
  vLight2 = ( iModelMat * vec4( lightPosition2 , 1. ) ).xyz;
  //vLight = ( iModelMat * vec4(  vec3( 400. , 1000. , 400. ) , 1. ) ).xyz;


  // Use this position to get the final position 
  gl_Position = projectionMatrix * modelViewMatrix * vec4( position , 1.);

}