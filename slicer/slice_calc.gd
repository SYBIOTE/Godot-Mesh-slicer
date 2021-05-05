class_name slice_calculator

enum MeshSide{
	Positive = 0,
	Negative = 1}

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
var _plane:Plane;
var _mesh:MeshInstance;
var _isSolid:bool ;
var _useSharedVertices:bool;
var _smoothVertices:bool ;
var _createReverseTriangleWindings:bool ;
var _current_surf_idx
var _origin
var _scale

func _init(plane:Plane , mesh:MeshInstance, isSolid:bool = true, createReverseTriangleWindings:bool = false,shareVertices:bool = false, smoothVertices:bool =false):
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
	_ComputeNewMeshes();
func _SetMeshData(side):
	var am = ArrayMesh.new()
	var mesh_array = []
	mesh_array.resize(ArrayMesh.ARRAY_MAX)
	if _mesh.mesh.get_surface_count() >0:
			if (side == MeshSide.Positive):
				for j in range(_mesh.mesh.get_surface_count()):
					mesh_array[Mesh.ARRAY_VERTEX] = PoolVector3Array(_positiveSideVertices[j]);
					mesh_array[Mesh.ARRAY_INDEX]  = PoolIntArray(_positiveSideTriangles[j]);
					mesh_array[Mesh.ARRAY_NORMAL] = PoolVector3Array(_positiveSideNormals[j]);
					mesh_array[Mesh.ARRAY_TEX_UV]= PoolVector2Array(_positiveSideUvs[j]);
					print("positive mesh is ",mesh_array[0].size()," ",mesh_array[1].size()," ",mesh_array[4].size()," ",mesh_array[8].size())
					am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
				_positiveSideMesh = am            
			else:
				for j in range(_mesh.mesh.get_surface_count()):
					mesh_array[Mesh.ARRAY_VERTEX] = PoolVector3Array(_negativeSideVertices[j]);
					mesh_array[Mesh.ARRAY_INDEX] = PoolIntArray(_negativeSideTriangles[j]);
					mesh_array[Mesh.ARRAY_NORMAL]  = PoolVector3Array(_negativeSideNormals[j]);
					mesh_array[Mesh.ARRAY_TEX_UV]= PoolVector2Array(_negativeSideUvs[j]); 
					print("negative mesh is ",mesh_array[0].size()," ",mesh_array[1].size()," ",mesh_array[4].size()," ",mesh_array[8].size())
					am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_array)
				_negativeSideMesh = am              
func _ComputeNewMeshes():
	print("computing")
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
#					print("vertices are = ",verts)
#					 //All verts are on the same side
#					print(vert1Side,vert2Side,vert3Side)
				if (vert1Side == vert2Side and vert2Side == vert3Side):
	#				//push_back the relevant triangle
					var side 
					if vert1Side:
						side = MeshSide.Positive 
					else:
						side = MeshSide.Negative
	#				print("same side")
					_AddTrianglesNormalAndUvs(side,  (vert1-_origin)/_scale, normal1, uv1, (vert2-_origin)/_scale, normal2, uv2, (vert3-_origin)/_scale, normal3, uv3, true, false);
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
						intersection1 = _GetRayPlaneIntersectionPointAndUv(vert2, uv2, vert3, uv3,intersection1Uv);
						intersection2 = _GetRayPlaneIntersectionPointAndUv(vert3, uv3, vert1, uv1,intersection2Uv);
	#					//push_back the positive or negative triangles
	#					print("new triangle: sending ",vert1,vert2,intersection1)
						_AddTrianglesNormalAndUvs(side1,  (vert1-_origin)/_scale, null, uv1, (vert2-_origin)/_scale, null, uv2, intersection1, null, intersection1Uv, _useSharedVertices, false);
	#					print("new triangle: sending ",vert1,intersection1,intersection2)
						_AddTrianglesNormalAndUvs(side1,  (vert1-_origin)/_scale, null, uv1, intersection1, null, intersection1Uv, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					print("new triangle: sending ",intersection1,intersection2,vert3)
						_AddTrianglesNormalAndUvs(side2, intersection1, null, intersection1Uv,  (vert3-_origin)/_scale, null, uv3, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					//vert 1 and 3 are on the same side
					elif (vert1Side == vert3Side):
	#					print("point 1 , 3 on same side")
	#					//Cast a ray from v1 to v2 and from v2 to v3 to get the intersections                       
						intersection1 = _GetRayPlaneIntersectionPointAndUv(vert1, uv1,vert2, uv2,intersection1Uv);
						intersection2 = _GetRayPlaneIntersectionPointAndUv(vert2, uv2,vert3, uv3,intersection2Uv);
	#					//push_back the positive triangles
	#					print("new triangle :sending ",vert1,intersection1,vert3)
						_AddTrianglesNormalAndUvs(side1, (vert1-_origin)/_scale, null, uv1, intersection1, null, intersection1Uv,  (vert3-_origin)/_scale, null, uv3, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,intersection2,vert3)
						_AddTrianglesNormalAndUvs(side1, intersection1, null, intersection1Uv, intersection2, null, intersection2Uv,  (vert3-_origin)/_scale, null, uv3, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,vert2,intersection2)
						_AddTrianglesNormalAndUvs(side2, intersection1, null, intersection1Uv,  (vert2-_origin)/_scale, null, uv2, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					//Vert1 is alone
					else:
	#					//Cast a ray from v1 to v2 and from v1 to v3 to get the intersections                       
	#					print("point 2 , 3 on same side")
						intersection1 = _GetRayPlaneIntersectionPointAndUv(vert1, uv1,vert2, uv2,intersection1Uv);
						intersection2 = _GetRayPlaneIntersectionPointAndUv(vert1, uv1,vert3, uv3,intersection2Uv);
	#					print("new triangle :sending ",vert1,intersection1,intersection2)
						_AddTrianglesNormalAndUvs(side1,(vert1-_origin)/_scale, null, uv1, intersection1, null, intersection1Uv, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,vert2,vert3)
						_AddTrianglesNormalAndUvs(side2,intersection1, null, intersection1Uv, (vert2-_origin)/_scale, null, uv2,  (vert3-_origin)/_scale, null, uv3, _useSharedVertices, false);
	#					print("new triangle :sending ",intersection1,vert3,intersection2)
						_AddTrianglesNormalAndUvs(side2,intersection1, null, intersection1Uv, (vert3-_origin)/_scale, null, uv3, intersection2, null, intersection2Uv, _useSharedVertices, false);
	#					//push_back the newly created points on the plane.
					_pointsAlongPlane[_current_surf_idx].push_back(intersection1);
					_pointsAlongPlane[_current_surf_idx].push_back(intersection2);
	#			//If the object is solid, join the new points along the plane otherwise do the reverse winding
			if (_isSolid):_JoinPointsAlongPlane();
			elif (_createReverseTriangleWindings):_AddReverseTriangleWinding();
			if (_smoothVertices):_SmoothVertices();
func _AddTrianglesNormalAndUvs(side, vertex1, normal1, uv1, vertex2, normal2,  uv2, vertex3, normal3, uv3, shareVertices,addFirst):
	if side == MeshSide.Positive:
		_AddTrianglesNormalsAndUvs(_positiveSideVertices[_current_surf_idx],_positiveSideTriangles[_current_surf_idx],_positiveSideNormals[_current_surf_idx],_positiveSideUvs[_current_surf_idx], vertex1, normal1, uv1, vertex2, normal2, uv2, vertex3, normal3, uv3, shareVertices, addFirst);
	else:
		_AddTrianglesNormalsAndUvs(_negativeSideVertices[_current_surf_idx],_negativeSideTriangles[_current_surf_idx],_negativeSideNormals[_current_surf_idx],_negativeSideUvs[_current_surf_idx], vertex1, normal1, uv1, vertex2, normal2, uv2, vertex3, normal3, uv3, shareVertices, addFirst);
func _AddTrianglesNormalsAndUvs(vertices,triangles,normals,uvs,vertex1,normal1,uv1,vertex2,normal2,uv2,vertex3,normal3,uv3,shareVertices,addFirst):
	var tri1Index = vertices.find(vertex1);
	if (addFirst):
		_ShiftTriangleIndeces(triangles);
#		//If a the vertex already exists we just push_back a triangle reference to it, if not push_back the vert to the list and then push_back the tri index
	if (tri1Index > -1 and shareVertices):              
		triangles.push_back(tri1Index);
	else:
		if (normal1 == null):
			normal1 = _ComputeNormal(vertex1, vertex2, vertex3);                    
		var i = null;
		if (addFirst):
			i = 0;
		_AddVertNormalUv(vertices,normals,uvs,triangles, vertex1,normal1, uv1, i);
	var tri2Index = vertices.find(vertex2);
	if (tri2Index > -1 and shareVertices):
		triangles.push_back(tri2Index);
	else:
		if (normal2 == null):
			normal2 = _ComputeNormal(vertex2, vertex3, vertex1);
		var i = null;
		if (addFirst):
			i = 1;
		_AddVertNormalUv(vertices,normals,uvs,triangles, vertex2,normal2, uv2, i);
	var tri3Index = vertices.find(vertex3);
	if (tri3Index > -1 and shareVertices):
		triangles.push_back(tri3Index);
	else:            
		if (normal3 == null):
			normal3 = _ComputeNormal(vertex3, vertex1, vertex2);
		var i = null;
		if (addFirst):
			i = 2;
		_AddVertNormalUv(vertices,normals,uvs,triangles, vertex3,normal3, uv3, i);#	print("triangle set is ",vertex1,vertex2,vertex3)
func _AddVertNormalUv(vertices, normals, uvs,triangles, vertex, normal, uv, index):
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
func _ShiftTriangleIndeces(triangles):
	for j in range(0,triangles.size(),3):
		triangles[j] += + 3;
		triangles[j + 1] += 3;
		triangles[j + 2] += 3;

#intersection plane builders
func _JoinPointsAlongPlane():
#		print("joining points ",_pointsAlongPlane[_current_surf_idx])
	var halfway = _GetHalfwayPoint();
	for i in range(0,_pointsAlongPlane[_current_surf_idx].size(),2):
		var firstVertex = _pointsAlongPlane[_current_surf_idx][i];
		var secondVertex = _pointsAlongPlane[_current_surf_idx][i + 1];
		var normal3 = _ComputeNormal(halfway, secondVertex, firstVertex).normalized();
		var direction = normal3.dot(_plane.normal);
		if(direction > 0):
			_AddTrianglesNormalAndUvs(MeshSide.Positive, halfway, -normal3, Vector2.ZERO, firstVertex, -normal3, Vector2.ZERO, secondVertex, -normal3, Vector2.ZERO, false, true);
			_AddTrianglesNormalAndUvs(MeshSide.Negative, halfway, normal3, Vector2.ZERO, secondVertex, normal3, Vector2.ZERO, firstVertex, normal3, Vector2.ZERO, false, true);
		else:
			_AddTrianglesNormalAndUvs(MeshSide.Positive, halfway, normal3, Vector2.ZERO, secondVertex, normal3, Vector2.ZERO, firstVertex, normal3, Vector2.ZERO, false, true);
			_AddTrianglesNormalAndUvs(MeshSide.Negative, halfway, -normal3, Vector2.ZERO, firstVertex, -normal3, Vector2.ZERO, secondVertex, -normal3, Vector2.ZERO, false, true);
func _GetHalfwayPoint():
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
func _GetRayPlaneIntersectionPointAndUv(vertex1,vertex1Uv,vertex2,vertex2Uv, uv):
	var pointOfintersection = _plane.intersects_segment(vertex2,vertex1)
#		print("point of intersection for ",vertex2," ",vertex1," is ",pointOfintersection)
	var distance = pointOfintersection.distance_to(vertex1);
	uv = _InterpolateUvs(vertex1Uv, vertex2Uv, distance);
	return (pointOfintersection-_origin)/_scale;
func _InterpolateUvs(uv1,uv2,distance):
	var uv = lerp(uv1, uv2, distance);
	return uv;
func _ComputeNormal(vertex1,vertex2,vertex3):
	var side1 = vertex2 - vertex1;
	var side2 = vertex3 - vertex1;
	var normal = side1.cross(side2);
	return normal;
func FlipNormals(currentNormals):
	var flippedNormals = [];

	for normal in currentNormals:
		flippedNormals.push_back(-normal);
	

	return flippedNormals
func _SmoothVertices():
	_DoSmoothing(_positiveSideVertices, _positiveSideNormals, _positiveSideTriangles);
	_DoSmoothing(_negativeSideVertices, _negativeSideNormals, _negativeSideTriangles);
func _DoSmoothing(vertices,normals,triangles):
	for x in normals:
		x = Vector3.ZERO

	for i in range(0,triangles.Count,3):
		var vertIndex1 = triangles[i];
		var vertIndex2 = triangles[i + 1];
		var vertIndex3 = triangles[i + 2];

		var triangleNormal = _ComputeNormal(vertices[vertIndex1], vertices[vertIndex2], vertices[vertIndex3]);

		normals[vertIndex1] += triangleNormal;
		normals[vertIndex2] += triangleNormal;
		normals[vertIndex3] += triangleNormal;

	for x in normals:
		x.normalized()
func _AddReverseTriangleWinding():
	var positiveVertsStartIndex = _positiveSideVertices.Count;
	_positiveSideVertices.AddRange(_positiveSideVertices);
	_positiveSideUvs.AddRange(_positiveSideUvs);
	_positiveSideNormals.AddRange(FlipNormals(_positiveSideNormals));
	var numPositiveTriangles = _positiveSideTriangles.Count;
#			//push_back reverse windings
	for i in range(0,numPositiveTriangles,3):
		_positiveSideTriangles.push_back(positiveVertsStartIndex + _positiveSideTriangles[i]);
		_positiveSideTriangles.push_back(positiveVertsStartIndex + _positiveSideTriangles[i + 2]);
		_positiveSideTriangles.push_back(positiveVertsStartIndex + _positiveSideTriangles[i + 1]);
	var negativeVertextStartIndex = _negativeSideVertices.Count;
#			//Duplicate the original vertices
	_negativeSideVertices.AddRange(_negativeSideVertices);
	_negativeSideUvs.AddRange(_negativeSideUvs);
	_negativeSideNormals.AddRange(FlipNormals(_negativeSideNormals));
	var numNegativeTriangles = _negativeSideTriangles.Count;
#		//push_back reverse windings
	for i in range(0,numNegativeTriangles,3):
		_negativeSideTriangles.push_back(negativeVertextStartIndex + _negativeSideTriangles[i]);
		_negativeSideTriangles.push_back(negativeVertextStartIndex + _negativeSideTriangles[i + 2]);
		_negativeSideTriangles.push_back(negativeVertextStartIndex + _negativeSideTriangles[i + 1]);

#get/create calculated meshes
func get_PositiveSideMesh():
	if (_positiveSideMesh == null):
		_positiveSideMesh = Mesh.new()
		_SetMeshData(MeshSide.Positive)
	return _positiveSideMesh
func get_NegativeSideMesh():
	if (_negativeSideMesh == null):
		_negativeSideMesh = Mesh.new()
		_SetMeshData(MeshSide.Negative)
	return _negativeSideMesh


