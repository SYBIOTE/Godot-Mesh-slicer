extends Area


var plane_point_a:Vector3 
var plane_point_b:Vector3 
var plane_point_c:Vector3

func _ready():
	plane_point_a = $mesh/base.global_transform.origin
func _on_Area_body_entered(body):
	if body is sliceable:
		plane_point_b =$mesh/tip.global_transform.origin

func _on_Area_body_exited(body):
	if body is sliceable:
		plane_point_c =$mesh/tip.global_transform.origin
		body.cut_object(Plane(plane_point_a,plane_point_b,plane_point_c))
