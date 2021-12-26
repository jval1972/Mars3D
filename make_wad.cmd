cd .\WADSRC
dir ..\..\bin\Mars3D.pk3
"C:\Program Files\7-Zip\7z.exe" a -r ..\..\bin\Mars3D.zip *.*
move ..\..\bin\Mars3D.zip ..\..\bin\Mars3D.pk3
dir ..\..\bin\Mars3D.pk3
pause