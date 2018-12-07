@echo off
cd temp
CLS

REM 解出 azw3 为 epub
for %%i in (*.azw3) do (
	..\kindleunpack -i "%%i"
	MOVE "%%~ni\mobi8\%%~ni.epub" "."
	RD /S /Q "%%~ni" 
)

REM 转为 mobi 并精简
for %%i in (*.epub) do (
	..\kindlegen "%%i"
	REM ..\kindlestrip.exe "%%~ni.mobi" "..\result\%%~ni.mobi"
	..\kindlestrip.exe "%%~ni.mobi" "%%~ni.mobi"
)

echo =======================================
echo     操作完成，文件保存在result目录下
echo =======================================        
pause

