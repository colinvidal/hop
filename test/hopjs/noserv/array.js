/*=====================================================================*/
/*    serrano/prgm/project/hop/3.0.x/test/hopjs/noserv/array.js        */
/*    -------------------------------------------------------------    */
/*    Author      :  Manuel Serrano                                    */
/*    Creation    :  Tue Oct  7 07:34:02 2014                          */
/*    Last change :  Thu Mar  5 10:22:34 2015 (serrano)                */
/*    Copyright   :  2014-15 Manuel Serrano                            */
/*    -------------------------------------------------------------    */
/*    Testing arrays                                                   */
/*=====================================================================*/
var assert = require( "assert" );

var s = [ 1, 2, 3, 4, 5 ];
var s2 = s.splice( 1, 0, 256 );

assert.deepEqual( s2, [] );
assert.deepEqual( s, [ 1, 256, 2, 3, 4, 5 ] );
