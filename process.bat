@echo off
cd temp
CLS

REM ��� azw3 Ϊ epub
for %%i in (*.azw3) do (
	..\kindleunpack -i "%%i"
	MOVE "%%~ni\mobi8\%%~ni.epub" "."
	RD /S /Q "%%~ni" 
)

REM תΪ mobi ������
for %%i in (*.epub) do (
	..\kindlegen "%%i"
	REM ..\kindlestrip.exe "%%~ni.mobi" "..\result\%%~ni.mobi"
	..\kindlestrip.exe "%%~ni.mobi" "%%~ni.mobi"
)

echo =======================================
echo     ������ɣ��ļ�������resultĿ¼��
echo =======================================        
pause

