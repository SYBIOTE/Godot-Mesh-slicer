
# Godot-Mesh-slicer
scripts to cut mesh / rigid bodies in godot at runtime implemented in GDscript


showcase : https://www.youtube.com/watch?v=ynZVK_XyaRc.  
play the demo scene to destroy the cube 
![Screenshot 2021-05-05 at 10 56 54 PM](https://user-images.githubusercontent.com/54761979/117183645-66e7eb80-adf5-11eb-89b6-728219f4b59c.png)
![Screenshot 2021-05-05 at 10 57 54 PM](https://user-images.githubusercontent.com/54761979/117183652-6a7b7280-adf5-11eb-9b17-09e449a973da.png)
## Use

Once you download/copy the slicer file into your project.  
There will a new node under rigid body called , sliceable.  
The sliceable node needs a mesh instance with mesh   
and a empty collision shape under it to function.     
Provide a cutting plane to the cut_object function (in world space).   
This will cut the rigid body into two rigidbodies.   

added cross section materials
## Todo 
improve normal calculation

## Bugs 
cuurently the sliced objects have the same materials but the applied textures on the material seem to be missing  
(might be linked to UV calculation) 
