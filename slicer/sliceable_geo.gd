extends RigidBody
class_name sliceable
export (int, 1, 10)var delete_at_children = 3 
export (int,LAYERS_3D_PHYSICS) var _cut_body_collision_layer
export (int,LAYERS_3D_PHYSICS) var _cut_body_collision_mask
export var _cut_body_gravity_scale:float
var _current_child_number = 0
var _mesh:MeshInstance = null
var _collider:CollisionShape = null
func _ready():
	for child in get_children():
		if child is MeshInstance:
			_mesh = child
#			print("found mesh")
		if child is CollisionShape:
			_collider = child
#			print("found collider")
		if _mesh!= null and _collider !=null:
			_mesh.global_transform.origin = global_transform.origin
			_mesh.create_convex_collision()
			_collider.shape = _mesh.get_child(0).get_child(0).shape
			_mesh.get_child(0).queue_free()
			_collider.scale = _mesh.scale
			_collider.rotation_degrees = _mesh.rotation_degrees
	#		print("children of object are ",get_children(),area.get_child(0))
	#		print("current_number ",current_child_number," delete at ",delete_at_children)
			if _current_child_number >= delete_at_children:
				queue_free()
			break
func _create_cut_body(_sign,mesh_instance,cutplane : Plane):
	var rigid_body_half = RigidBody.new();
	rigid_body_half.collision_layer = _cut_body_collision_layer
	rigid_body_half.collision_mask = _cut_body_collision_mask
	rigid_body_half.gravity_scale = _cut_body_gravity_scale
#	rigid_body_half.physics_material_override = load("res://scenes/models/BeepCube_Cut.phymat");
	rigid_body_half.global_transform = global_transform;
	#create mesh
	var object = MeshInstance.new()
	object.mesh = mesh_instance
	object.scale = _mesh.scale
	if _mesh.mesh.get_surface_count() > 0:
#		print(_mesh.mesh.get_surface_count())
		for i in range(_mesh.mesh.get_surface_count()):
			var mat = _mesh.mesh.surface_get_material(i)
			object.mesh.surface_set_material(i,mat)
	#create collider 
	var coll = CollisionShape.new()
	#add the body to sce
	rigid_body_half.add_child(object)
	rigid_body_half.add_child(coll)
	rigid_body_half.set_script(self.get_script())
	rigid_body_half._cut_body_collision_layer = _cut_body_collision_layer
	rigid_body_half._cut_body_collision_mask = _cut_body_collision_mask
	rigid_body_half._cut_body_gravity_scale = _cut_body_gravity_scale
	rigid_body_half._current_child_number = _current_child_number+1 
	rigid_body_half.delete_at_children =  delete_at_children
	get_parent().add_child(rigid_body_half)
func cut_object(cutplane:Plane):
	var slices = slice_calculator.new(cutplane,_mesh,true)
#	print("+ve mesh is ",slices.negative_mesh())
#	print("-ve mesh is ",slices.positive_mesh())
	_create_cut_body(-1,slices.negative_mesh(),cutplane);
	_create_cut_body( 1,slices.positive_mesh(),cutplane);
	queue_free();
func _get_configuration_warning():
		var warning = PoolStringArray()
		if _mesh == null: 
			warning.append("please add a Mesh Instance with some mesh")
		return warning.join("\n")
