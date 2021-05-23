class_name slice_calculator

enum MeshSide{
	Positive = 0,
	Negative = 1
	OnPlane =2}

var _surfaceCount

var _positiveSideMesh:Mesh;
var _positiveSideVertices;
var _positiveSideTriangles;
var _positiveSideUvs;
var _positiveSideNormals;

var _negativeSideMesh:Mesh;
var _negativeSideVertices;
var _negativeSideTriangles;
var _negativeSideUvs;
var _negativeSideNormals;

var _pointsAlongPlane;
var _onplaneSideVertices;
var _onplaneSideTriangles;
var _onplaneSideUvs;
var _onplaneSideNormals;

var _plane:Plane;
var _mesh:MeshInstance;
var _cross_section_material:bool = false;
var _UV_scale
var _UV_offset

var _isSolid:bool;
var _useSharedVertices:bool;
var _smoothVertices:bool ;
var _createReverseTriangleWindings:bool;
var _current_surf_idx:int
var _origin:Vector3
var _scale:Vector3

func _init(plane:Plane , mesh:MeshInstance,isSolid:bool = true, cross_section_material:Material= null,uv_scale = 1,uv_offset = Vector2(0,0),createReverseTriangleWindings:bool = false,shareVertices:bool = false, smoothVertices:bool =false):
	if cross_section_material != null:
		_cross_section_material = true
		_isSolid = true
		_onplaneSideVertices = [];
		_onplaneSideTriangles= [];
		_onplaneSideUvs=[];
		_onplaneSideNormals=[];
	if _cross_section_material:
		_surfaceCount = mesh.mesh.get_surface_count()+1
		_UV_scale = uv_scale
		_UV_offset = uv_offset
	else:
		_surfaceCount = mesh.mesh.get_surface_count()
	_current_surf_idx = 0 
	_positiveSideTriangles= []; 
	_positiveSideVertices = [];
	_positiveSideNormals  = [];
	_positiveSideUvs = []; 
	_negativeSideTriangles = [];
	_negativeSideVertices = [];
	_negativeSideNormals  = []; 
	_negativeSideUvs = [];
	_pointsAlongPlane  = [];
	for i in range(_surfaceCount):
		_positiveSideTriangles.append([]); 
		_positiveSideVertices.append([]);
		_positiveSideNormals.append([])
		_positiveSideUvs.append([]); 
		_negativeSideTriangles.append([]);
		_negativeSideVertices.append([]);
		_negativeSideNormals.append([]); 
		_negativeSideUvs.append([]);
		_pointsAlongPlane.append([]);
	_mesh = mesh;
	_plane = plane;
	_isSolid = isSolid;
	_createReverseTriangleWindings = createReverseTriangleWindings;
	_useSharedVertices = shareVertices;
	_smoothVertices = smoothVertices;
	_origin = _mesh.global_transform.origin
	_scale = _mesh.scale
	_compute_mesh();
func _set_mesh(side):
	var am = ArrayMesh.new()
	var mesh_array = []
	mesh_array.resize(ArrayMesh.ARRAY_MAX)
	if _surfaceCount > 0:
#		print("in slice calc",_surfaceCount)
		if (side == MeshSide.Positive):
			for j in range(_surfaceCount):
				mesh_array[Mesh.ARRAY_VERTEX] = PoolVector3Array(_positiveSideVertices[j]);
				mesh_array[Mesh.ARRAY_INDEX]  = PoolIntArray(_positiveSideTriangles[j]);
				mesh_array[Mesh.ARRAY_NORMAL] = PoolVector3Array(_positiveSideNormals[j]);
				mesh_array[Mesh.ARRAY_TEX_UV]= PoolVector2Array(_positiveSideUvs[j]);
#				print("positive mesh is ",mesh_array[0].size()," ",mesh_array[1].size()," ",mesh_array[4].size()," ",mesh_array[8].size())
				if _cross_section_material and j == _surfaceCount-1:
					mesh_array[Mesh.ARRAY_VERTEX] = PoolVector3Array(_onplaneSideVertices);
					mesh_array[Mesh.ARRAY_INDEX]  = PoolIntArray(_onplaneSideTriangles);
					mesh_array[Mesh.ARRAY_NORMAL] = PoolVector3Array(_onplaneSideNormals);
					mesh_array[Mesh.ARRAY_TEX_UV]= PoolVector2Array(_onplaneSideUvs);
				am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
			_positiveSideMesh = am            
		else:
			for j in range(_surfaceCount):
				mesh_array[Mesh.ARRAY_VERTEX] = PoolVector3Array(_negativeSideVertices[j]);
				mesh_array[Mesh.ARRAY_INDEX] = PoolIntArray(_negativeSideTriangles[j]);
				mesh_array[Mesh.ARRAY_NORMAL]  = PoolVector3Array(_negativeSideNormals[j]);
				mesh_array[Mesh.ARRAY_TEX_UV]= PoolVector2Array(_negativeSideUvs[j]); 
#					print("negative mesh is ",mesh_array[0].size()," ",mesh_array[1].size()," ",mesh_array[4].size()," ",mesh_array[8].size())
				if _cross_section_material and j == _surfaceCount-1:
					mesh_array[Mesh.ARRAY_VERTEX] = PoolVector3Array(_onplaneSideVertices);
					mesh_array[Mesh.ARRAY_INDEX]  = PoolIntArray(_onplaneSideTriangles);
					mesh_array[Mesh.ARRAY_NORMAL] = PoolVector3Array(_onplaneSideNormals);
					mesh_array[Mesh.ARRAY_TEX_UV]= PoolVector2Array(_onplaneSideUvs);
				am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
			_negativeSideMesh = am              
func _compute_mesh():
	if _mesh.mesh.get_surface_count() >0:
		for j in range(_mesh.mesh.get_surface_count()):
			_current_surf_idx = j
#			print("current surface = ",_current_surf_idx)
			var meshTriangles = _mesh.mesh.surface_get_arrays(_current_surf_idx)[Mesh.ARRAY_INDEX];
			var meshVerts = Array(_mesh.mesh.surface_get_arrays(_current_surf_idx)[Mesh.ARRAY_VERTEX]);
			var meshNormals = _mesh.mesh.surface_get_arrays(_current_surf_idx)[Mesh.ARRAY_NORMAL];
			var meshUvs = _mesh.mesh.surface_get_arrays(_current_surf_idx)[Mesh.ARRAY_TEX_UV];
			for i in range(0,meshTriangles.size(),3):
	#			//We need the verts in order so that we know which way to wind our new mesh triangles.
				var verts = []
				var vert1 = meshVerts[meshTriangles[i]];
				var vert1Index = meshVerts.find(vert1);
				vert1 = _mesh.global_transform.xform(vert1)
				verts.append(vert1)
				var uv1 = meshUvs[vert1Index];
				var normal1 = meshNormals[vert1Index];
				var vert1Side = _plane.is_point_over(vert1)
				
				var vert2 = meshVerts[meshTriangles[i + 1]];
				var vert2Index = meshVerts.find(vert2);
				vert2 = _mesh.global_transform.xform(vert2)
				verts.append(vert2)
				var uv2 = meshUvs[vert2Index];
				var normal2 = meshNormals[vert2Index];
				var vert2Side = _plane.is_point_over(vert2);
				var vert3 =  meshVerts[meshTriangles[i + 2]];
				var vert3Index = meshVerts.find(vert3);
				vert3  = _mesh.global_transform.xform(vert3)
				
				verts.append(vert3)
				var uv3 = meshUvs[vert3Index];
				var normal3 = meshNormals[vert3Index];
				var vert3Side =_plane.is_point_over(vert3);
				
#				print("normals= ",[normal1,normal2,normal3])
#				 //All verts are on the same side
#				print(vert1Side,vert2Side,vert3Side)
				if (vert1Side == vert2Side and vert2Side == vert3Side):
	#				//push_back the relevant triangle
					var side 
					if vert1Side:
						side = MeshSide.Positive 
					else:
						side = MeshSide.Negative
	#				print("same side")
					_set_mesh_side(side,(vert1-_origin)/_scale,normal1,uv1,(vert2-_origin)/_scale,normal2,uv2,(vert3-_origin)/_scale, normal3, uv3, true, false);
				else:
	#				//we need the two points where the plane intersects the triangle.
					var intersection1;var intersection2;
					var intersection1Uv;var intersection2Uv;
					var side1;var side2;
					if (vert1Side):
						side1 = MeshSide.Positive 
						side2 = MeshSide.Negative 
					else:
						side1 = MeshSide.Negative;
						side2 = MeshSide.Positive;
	#					//vert 1 and 2 are on the same side
					if (vert1Side == vert2Side):
	#					print("point 1 , 2 on same side")
	#					//Cast a ray from v2 to v3 and from v3 to v1 to get the intersections                       
						intersection1 = _get_plane_intersection_point_uv(vert2, uv2, vert3, uv3,intersection1Uv);
						intersection1Uv=intersection1[1]
						intersection1=intersection1[0]
						intersection2 = _get_plane_intersection_point_uv(vert3, uv3, vert1, uv1,intersection2Uv);
						intersection2Uv=intersection2[1]
						intersection2=intersection2[0]
	#					//push_back the positive or negative triangles
	#					print("new triangle: sending ",vert1,vert2,intersection1)
						_set_mesh_side(side1, (vert1-_origin)/_scale, null, uv1, (vert2-_origin)/_scale, null, uv2, intersection1, null, intersection1Uv, _useSharedVertices, false);
	#					print("new triangle: sending ",vert1,intersection1,intersection2)
						_set_mesh_side(side1, (vert1-_origin)/_scale, null, uv1, intersection1, null, intersection1Uv, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					print("new triangle: sending ",intersection1,intersection2,vert3)
						_set_mesh_side(side2, intersection1, null, intersection1Uv,  (vert3-_origin)/_scale, null, uv3, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					//vert 1 and 3 are on the same side
					elif (vert1Side == vert3Side):
	#					print("point 1 , 3 on same side")
	#					//Cast a ray from v1 to v2 and from v2 to v3 to get the intersections                       
						intersection1 = _get_plane_intersection_point_uv(vert1, uv1,vert2, uv2,intersection1Uv);
						intersection1Uv=intersection1[1]
						intersection1=intersection1[0]
						intersection2 = _get_plane_intersection_point_uv(vert2, uv2,vert3, uv3,intersection2Uv);
						intersection2Uv=intersection2[1]
						intersection2=intersection2[0]
#						//push_back the positive triangles
	#					print("new triangle :sending ",vert1,intersection1,vert3)
						_set_mesh_side(side1, (vert1-_origin)/_scale, null, uv1, intersection1, null, intersection1Uv,  (vert3-_origin)/_scale, null, uv3, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,intersection2,vert3)
						_set_mesh_side(side1, intersection1, null, intersection1Uv, intersection2, null, intersection2Uv,  (vert3-_origin)/_scale, null, uv3, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,vert2,intersection2)
						_set_mesh_side(side2, intersection1, null, intersection1Uv,  (vert2-_origin)/_scale, null, uv2, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					//Vert1 is alone
					else:
	#					//Cast a ray from v1 to v2 and from v1 to v3 to get the intersections                       
	#					print("point 2 , 3 on same side")
						intersection1 = _get_plane_intersection_point_uv(vert1, uv1,vert2, uv2,intersection1Uv);
						intersection1Uv=intersection1[1]
						intersection1=intersection1[0]
						intersection2 = _get_plane_intersection_point_uv(vert1, uv1,vert3, uv3,intersection2Uv);
						intersection2Uv=intersection2[1]
						intersection2=intersection2[0]
#						print("new triangle :sending ",vert1,intersection1,intersection2)
						_set_mesh_side(side1,(vert1-_origin)/_scale, null, uv1, intersection1, null, intersection1Uv, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,vert2,vert3)
						_set_mesh_side(side2,intersection1, null, intersection1Uv, (vert2-_origin)/_scale, null, uv2,  (vert3-_origin)/_scale, null, uv3, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,vert3,intersection2)
						_set_mesh_side(side2,intersection1, null, intersection1Uv, (vert3-_origin)/_scale, null, uv3, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					//push_back the newly created points on the plane.
#						print("depositing at intersection points at ",_current_surf_idx)
					_pointsAlongPlane[_current_surf_idx].push_back(intersection1);
					_pointsAlongPlane[_current_surf_idx].push_back(intersection2);
						
		if _cross_section_material:
			if (_isSolid):_make_intersection_plane_cross_section();
			for j in range(_mesh.mesh.get_surface_count()):
				_current_surf_idx = j
				if (_createReverseTriangleWindings):_add_reverse_winded_triangle();
				if (_smoothVertices):_smooth_vertex();
		else:
			for j in range(_mesh.mesh.get_surface_count()):
				_current_surf_idx = j
				if (_isSolid):_make_intersection_plane();
				elif (_createReverseTriangleWindings):_add_reverse_winded_triangle();
				if (_smoothVertices):_smooth_vertex();
func _set_mesh_side(side, vertex1, normal1, uv1, vertex2, normal2,  uv2, vertex3, normal3, uv3, shareVertices,addFirst):
	if side == MeshSide.Positive:
		_add_index_normal_uv(_positiveSideVertices[_current_surf_idx],_positiveSideTriangles[_current_surf_idx],_positiveSideNormals[_current_surf_idx],_positiveSideUvs[_current_surf_idx], vertex1, normal1, uv1, vertex2, normal2, uv2, vertex3, normal3, uv3, shareVertices, addFirst);
	elif side == MeshSide.Negative:
		_add_index_normal_uv(_negativeSideVertices[_current_surf_idx],_negativeSideTriangles[_current_surf_idx],_negativeSideNormals[_current_surf_idx],_negativeSideUvs[_current_surf_idx], vertex1, normal1, uv1, vertex2, normal2, uv2, vertex3, normal3, uv3, shareVertices, addFirst);
	else:
		_add_index_normal_uv(_onplaneSideVertices,_onplaneSideTriangles,_onplaneSideNormals,_onplaneSideUvs, vertex1, normal1, uv1, vertex2, normal2, uv2, vertex3, normal3, uv3, shareVertices, addFirst);
func _add_index_normal_uv(vertices,triangles,normals,uvs,vertex1,normal1,uv1,vertex2,normal2,uv2,vertex3,normal3,uv3,shareVertices,addFirst):
	if (addFirst):
		_shift_triangle_index(triangles);
#	//If a the vertex already exists we just push_back a triangle reference to it, if not push_back the vert to the list and then push_back the triindex
	var tri1Index = vertices.find(vertex1);
	if (tri1Index > -1 and shareVertices):triangles.push_back(tri1Index);
	else:
		if (normal1 == null):
			normal1 = _compute_normal(vertex1, vertex2, vertex3);                    
		var i = null;
		if (addFirst):i = 0;
		_add_vertex_normal_uv(vertices,normals,uvs,triangles, vertex1,normal1, uv1, i);
	var tri2Index = vertices.find(vertex2);
	if (tri2Index > -1 and shareVertices):triangles.push_back(tri2Index);
	else:
		if (normal2 == null):
			normal2 = _compute_normal(vertex2, vertex3, vertex1);
		var i = null;
		if (addFirst):i = 1;
		_add_vertex_normal_uv(vertices,normals,uvs,triangles, vertex2,normal2, uv2, i);
	var tri3Index = vertices.find(vertex3);
	if (tri3Index > -1 and shareVertices):triangles.push_back(tri3Index);
	else:            
		if (normal3 == null):
			normal3 = _compute_normal(vertex3, vertex1, vertex2);
		var i = null;
		if (addFirst):i = 2;
		_add_vertex_normal_uv(vertices,normals,uvs,triangles, vertex3,normal3, uv3, i);#	print("triangle set is ",vertex1,vertex2,vertex3)
func _add_vertex_normal_uv(vertices, normals, uvs,triangles, vertex, normal, uv, index):
	if (index != null):
		var i = index;
		vertices.insert(i, vertex);
		uvs.insert(i, uv);
		normals.insert(i, normal);
		triangles.insert(i, i);
	else:
		vertices.push_back(vertex);
		normals.push_back(normal);
		uvs.push_back(uv);
		triangles.push_back(vertices.find(vertex));
func _shift_triangle_index(triangles):
	for j in range(0,triangles.size(),3):
		triangles[j] += + 3;
		triangles[j + 1] += 3;
		triangles[j + 2] += 3;

#intersection plane builders
# cross section material applied
func _make_intersection_plane_cross_section():
#	print("_make_intersection_plane_cross_section")
	var max_points_surface = 0
	for i in _pointsAlongPlane.size():
		_pointsAlongPlane[_surfaceCount-1] += _pointsAlongPlane[i]
	var halfway = _get_plane_halfway_points_cross_section();
	for i in range(0,_pointsAlongPlane[_surfaceCount-1].size(),2):
		var firstVertex:Vector3 = _pointsAlongPlane[_surfaceCount-1][i];
		var secondVertex:Vector3 = _pointsAlongPlane[_surfaceCount-1][i+1];
		var normal3 = _compute_normal(halfway, secondVertex, firstVertex).normalized();
		var direction = normal3.dot(_plane.normal);
		if direction<0:
			_set_mesh_side(MeshSide.OnPlane, halfway, normal3,_planar_UV(halfway,normal3),firstVertex,normal3,_planar_UV(firstVertex,normal3),secondVertex,normal3,_planar_UV(secondVertex,normal3),false,true);
		else:
			_set_mesh_side(MeshSide.OnPlane, halfway, -normal3,_planar_UV(halfway,-normal3),firstVertex,-normal3,_planar_UV(firstVertex,-normal3),secondVertex,-normal3,_planar_UV(secondVertex,-normal3),false,true);
	_pointsAlongPlane.clear()
func _get_plane_halfway_points_cross_section():
#	print("_get_plane_halfway_points_cross_section")
	var distance 
	if(_pointsAlongPlane[_surfaceCount-1].size() > 0):
		distance =0
		var firstPoint = _pointsAlongPlane[_surfaceCount-1][0];
		var furthestPoint = Vector3.ZERO;
		for point in _pointsAlongPlane[_surfaceCount-1]:
			var currentDistance = 0;
			currentDistance = firstPoint.distance_to(point);
			if (currentDistance > distance):
				distance = currentDistance;
				furthestPoint = point;
		return lerp(firstPoint,furthestPoint, 0.5);
	else:
		distance = 0;
		return Vector3.ZERO;     
# when no materials applied 
func _make_intersection_plane():
#	print("joining points ",_pointsAlongPlane[_current_surf_idx])
#	print("_make_intersection_plane")
	var halfway = _get_plane_halfway_points();
	for i in range(0,_pointsAlongPlane[_current_surf_idx].size(),2):
		var firstVertex = _pointsAlongPlane[_current_surf_idx][i];
		var secondVertex = _pointsAlongPlane[_current_surf_idx][i + 1];
		var normal3 = _compute_normal(halfway, secondVertex, firstVertex).normalized();
		var direction = normal3.dot(_plane.normal);
		if(direction > 0):
			_set_mesh_side(MeshSide.Positive, halfway, -normal3, Vector2.ZERO, firstVertex, -normal3, Vector2.ZERO, secondVertex, -normal3, Vector2.ZERO, false, true);
			_set_mesh_side(MeshSide.Negative, halfway, normal3, Vector2.ZERO, secondVertex, normal3, Vector2.ZERO, firstVertex, normal3, Vector2.ZERO, false, true);
		else:
			#changed the normal quickly
			_set_mesh_side(MeshSide.Positive, halfway, normal3, Vector2.ZERO, secondVertex, normal3, Vector2.ZERO, firstVertex, normal3, Vector2.ZERO, false, true);
			_set_mesh_side(MeshSide.Negative, halfway, -normal3, Vector2.ZERO, firstVertex, -normal3, Vector2.ZERO, secondVertex, -normal3, Vector2.ZERO, false, true);   
func _get_plane_halfway_points():
	var distance 
	if(_pointsAlongPlane[_current_surf_idx].size() > 0):
		distance =0
		var firstPoint = _pointsAlongPlane[_current_surf_idx][0];
		var furthestPoint = Vector3.ZERO;
		for point in _pointsAlongPlane[_current_surf_idx]:
			var currentDistance = 0;
			currentDistance = firstPoint.distance_to(point);
			if (currentDistance > distance):
				distance = currentDistance;
				furthestPoint = point;
		return lerp(firstPoint,furthestPoint, 0.5);
	else:
		distance = 0;
		return Vector3.ZERO;      
#utility functions
func _planar_UV(vertex,projection_axis):
	var U :Vector3 = projection_axis.cross(Vector3(0,0,1))
	if U.dot(U)<.001:
		U = Vector3(1,0,0)
	else:
		U = U.normalized()
	var V = projection_axis.cross(U).normalized()
	return Vector2(vertex.dot(U)+_UV_offset.x,vertex.dot(V)+_UV_offset.y)*_UV_scale
	
func _get_plane_intersection_point_uv(vertex1,vertex1Uv,vertex2,vertex2Uv, uv):
	var pointOfintersection = _plane.intersects_segment(vertex2,vertex1)
#	print("point of intersection for ",vertex2.round()," ",vertex1.round()," is ",((pointOfintersection-_origin)/_scale).round())
	var distance = pointOfintersection.distance_to(vertex1);
	uv = _interpolate_uv(vertex1Uv, vertex2Uv, distance);
	return [(pointOfintersection-_origin)/_scale , uv];
func _interpolate_uv(uv1,uv2,distance):
	var uv = lerp(uv1, uv2, distance);
	return uv;
func _compute_normal(vertex1,vertex2,vertex3):
	var side1 =  vertex2 - vertex1 ;
	var side2 =  vertex3 - vertex1;
	var normal = side2.cross(side1);
	return normal;
func _flip_normal(currentNormals):
	var flippedNormals = [];
	for normal in currentNormals:
		flippedNormals.push_back(-normal);
	return flippedNormals
func _smooth_vertex():
	print("smooth")
	_smoothen(_positiveSideVertices[_current_surf_idx], _positiveSideNormals[_current_surf_idx], _positiveSideTriangles[_current_surf_idx]);
	_smoothen(_negativeSideVertices[_current_surf_idx], _negativeSideNormals[_current_surf_idx], _negativeSideTriangles[_current_surf_idx]);
func _smoothen(vertices,normals,triangles):
	for x in normals:
		x = Vector3.ZERO

	for i in range(0,triangles.size(),3):
		var vertIndex1 = triangles[i];
		var vertIndex2 = triangles[i + 1];
		var vertIndex3 = triangles[i + 2];

		var triangleNormal = _compute_normal(vertices[vertIndex1], vertices[vertIndex2], vertices[vertIndex3]);

		normals[vertIndex1] += triangleNormal;
		normals[vertIndex2] += triangleNormal;
		normals[vertIndex3] += triangleNormal;

	for x in normals:
		x.normalized()
func _add_reverse_winded_triangle():
	print("rev winded triangle")
	var positiveVertsStartIndex = _positiveSideVertices[_current_surf_idx].size();
	_positiveSideVertices[_current_surf_idx].append_array(_positiveSideVertices[_current_surf_idx]);
	_positiveSideUvs[_current_surf_idx].append_array(_positiveSideUvs[_current_surf_idx]);
	_positiveSideNormals[_current_surf_idx].append_array(_flip_normal(_positiveSideNormals[_current_surf_idx]));
	var numPositiveTriangles = _positiveSideTriangles[_current_surf_idx].size();
#			//push_back reverse windings
	for i in range(0,numPositiveTriangles,3):
		_positiveSideTriangles[_current_surf_idx].push_back(positiveVertsStartIndex + _positiveSideTriangles[_current_surf_idx][i]);
		_positiveSideTriangles[_current_surf_idx].push_back(positiveVertsStartIndex + _positiveSideTriangles[_current_surf_idx][i + 2]);
		_positiveSideTriangles[_current_surf_idx].push_back(positiveVertsStartIndex + _positiveSideTriangles[_current_surf_idx][i + 1]);
	var negativeVertextStartIndex = _negativeSideVertices[_current_surf_idx].size();
#			//Duplicate the original vertices
	_negativeSideVertices[_current_surf_idx].append_array(_negativeSideVertices[_current_surf_idx]);
	_negativeSideUvs[_current_surf_idx].append_array(_negativeSideUvs[_current_surf_idx]);
	_negativeSideNormals[_current_surf_idx].append_array(_flip_normal(_negativeSideNormals[_current_surf_idx]));
	var numNegativeTriangles = _negativeSideTriangles[_current_surf_idx].size();
#		//push_back reverse windings
	for i in range(0,numNegativeTriangles,3):
		_negativeSideTriangles[_current_surf_idx].push_back(negativeVertextStartIndex + _negativeSideTriangles[_current_surf_idx][i]);
		_negativeSideTriangles[_current_surf_idx].push_back(negativeVertextStartIndex + _negativeSideTriangles[_current_surf_idx][i + 2]);
		_negativeSideTriangles[_current_surf_idx].push_back(negativeVertextStartIndex + _negativeSideTriangles[_current_surf_idx][i + 1]);

#get/create calculated meshes
func positive_mesh():
	if (_positiveSideMesh == null):
		_positiveSideMesh = Mesh.new()
		_set_mesh(MeshSide.Positive)
	return _positiveSideMesh
func negative_mesh():
	if (_negativeSideMesh == null):
		_negativeSideMesh = Mesh.new()
		_set_mesh(MeshSide.Negative)
	return _negativeSideMesh


