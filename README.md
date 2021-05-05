# Godot-Mesh-slicer
scripts to cut mesh / rigid bodies in godot at runtime implemented in GDscript


showcase : https://www.youtube.com/watch?v=ynZVK_XyaRc

## Use
Once you download/copy the slicer file into your project.  
There will a new node under rigid body called , sliceble.  
The sliceable object needs a mesh instance with mesh   
and a empty collision shape under it to function.     
Provide a cutting plane to the cut_object function (in world space).   
This will cut the rigid body into two rigidbodies.    
## Todo 
add cross section textures  
improve normal calculation

## Bugs 
cuurently the sliced objects have the same materials but the applied textures on the material seem to be missing  
(might be linked to UV calculation) 
