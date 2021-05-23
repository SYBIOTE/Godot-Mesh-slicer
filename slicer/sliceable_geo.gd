tool
extends RigidBody
class_name sliceable
export var enabled:bool = true
export (int, 1, 10)var _delete_at_children = 3 
export (int, 1, 10)var _disable_at_children = 3 
export (int,LAYERS_3D_PHYSICS) var _cut_body_collision_layer
export (int,LAYERS_3D_PHYSICS) var _cut_body_collision_mask
export var _cut_body_gravity_scale:float
export (Material)var _cross_section_material =  null
export var _cross_section_texture_UV_scale:float = 1
export var _cross_section_texture_UV_offset:Vector2 = Vector2(0,0)
export var _apply_force_on_cut:bool = false
export var _normal_force_on_cut:float  = 1
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
			if _current_child_number >= _delete_at_children:
				queue_free()
			if _current_child_number >= _disable_at_children:
				enabled = false
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
		var material_count
		if _cross_section_material != null:
			 material_count= _mesh.mesh.get_surface_count()+1
		else:
			 material_count= _mesh.mesh.get_surface_count()
		for i in range(material_count):
			var mat 
			if i == material_count -1 and _cross_section_material != null:
				mat = _cross_section_material
			else:
				mat = _mesh.mesh.surface_get_material(i)
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
	rigid_body_half._delete_at_children =  _delete_at_children
	rigid_body_half._disable_at_children = _disable_at_children
	rigid_body_half._cross_section_material = _cross_section_material
	rigid_body_half._normal_force_on_cut = _normal_force_on_cut
	get_parent().add_child(rigid_body_half)
	if _apply_force_on_cut:
		rigid_body_half.apply_central_impulse(_sign*cutplane.normal*_normal_force_on_cut)
func cut_object(cutplane:Plane):
	#  there are a lot of parameters for the constructor
	#-------------------------------------------------
	#  cutplane = plane to cut mesh with , in global space
	#  mesh =  the mesh you want to cut
	#  is solid = if you want a surface for cross section
	#  cross_section_material = cross section material you want for the cut pieces , overides is_solid to be true
	#  cross section texture UV scale , scale of the planar projection UV
	#  cross section texture UV offset , offset of the Planar projection UV
	#  createReverseTriangleWindings 
	#  shareVertices
	#  smoothVertices
	#-------------------------------------------------
	if enabled: 
		var slices = slice_calculator.new(cutplane,_mesh,true,_cross_section_material,_cross_section_texture_UV_scale,_cross_section_texture_UV_offset,true,true,true)
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
