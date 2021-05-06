tool
extends Area


var plane_point_a:Vector3 
var plane_point_b:Vector3 
var plane_point_c:Vector3


func _on_Area_body_exited(body):
	if body is sliceable:
		plane_point_a = $mesh/A.global_transform.origin
		plane_point_b = $mesh/B.global_transform.origin
		plane_point_c = $mesh/C.global_transform.origin
		body.cut_object(Plane(plane_point_a,plane_point_b,plane_point_c))
