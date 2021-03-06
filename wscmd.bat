@if (true == false) @end /*!
@echo off


setlocal enabledelayedexpansion


set wscmd.started=1


:wscmd.start


:: Set the name and version
set wscmd.name=Windows Scripting Command
set wscmd.version=0.23.20 Beta
set wscmd.copyright=Copyright ^(C^) 2009-2015, 2019, 2020 Ildar Shaimordanov


:: Prevent re-parsing of command line arguments
if not defined wscmd.started goto wscmd.2
set wscmd.started=


:: Parse command line arguments and set needful variables
set wscmd.temp=
set wscmd.inline=
set wscmd.inproc=
set wscmd.script=
set wscmd.script.n=
set wscmd.script.p=
set wscmd.script.begin=
set wscmd.script.end=
set wscmd.script.beginfile=
set wscmd.script.endfile=
set wscmd.engine=javascript
set wscmd.var=
set wscmd.compile=
set wscmd.debug=
set wscmd.quiet=
set wscmd.execute=


:: Help
if /i "%~1" == "/h" (
	goto wscmd.help
)

if /i "%~1" == "/help" (
	goto wscmd.help
)


:: Configuration file manual
if /i "%~1" == "/man" (
	goto wscmd.man
)


:: Compiling and debugging modes
if /i "%~1" == "/compile" (
	set wscmd.compile=1
	shift /1
) else if /i "%~1" == "/embed" (
	set wscmd.compile=2
	shift /1
) else if /i "%~1" == "/debug" (
	set wscmd.debug=1
	shift /1
)


:: Variable definition
:wscmd.var.again
if /i not "%~1" == "/v" goto wscmd.var.end

	set "wscmd.var=!wscmd.var!var %2 = "%3";"
	shift /1
	shift /1
	shift /1

goto wscmd.var.again
:wscmd.var.end

if defined wscmd.var (
	set wscmd.var="!wscmd.var!"
	call :wscmd.unquote wscmd.var
)


:: Interactive mode
if "%~1" == "" (
	shift /1
	goto wscmd.1
)

if /i "%~1" == "/i" (
	shift /1
	goto wscmd.1
)

if /i "%~1" == "/q" (
	set wscmd.quiet=/q
	shift /1
	goto wscmd.1
)


:: What language will be used
if /i "%~1" == "/js" (
	set wscmd.engine=javascript
	shift /1
) else if /i "%~1" == "/vbs" (
	set wscmd.engine=vbscript
	shift /1
)


:: Code or script file
if /i "%~1" == "/e" goto wscmd.opt.e.1

	rem wscmd ... "filename" ...
	set wscmd.inline=
	set wscmd.inproc=
	set wscmd.script=%~1
	if defined wscmd.script if not exist "!wscmd.script!" (
		echo.File not found "!wscmd.script!".

		endlocal
		exit /b 1
	)
	call :wscmd.engine "!wscmd.script!"
	shift /1

goto wscmd.opt.e.2
:wscmd.opt.e.1

	rem wscmd ... /e ... "string" ...
	set wscmd.inline=1
	set wscmd.inproc=

:wscmd.opt.e.again

	for %%k in ( p n begin end beginfile endfile ) do (
		if /i "%~2" == "/%%~k" (
			set wscmd.inproc=1
			set wscmd.script.%%~k=%3
			call :wscmd.unquote wscmd.script.%%~k
			shift /1
			shift /1
			goto wscmd.opt.e.again
		)
	)

	rem wscmd ... /e "string" ...
	if not defined wscmd.inproc (
		set wscmd.script=%2
		call :wscmd.unquote wscmd.script
		shift /1
	)

	shift /1

:wscmd.opt.e.2


:wscmd.1


:: Parse program arguments
if "%~1" == "" goto wscmd.2
set wscmd.args=%wscmd.args% %1
shift /1
goto wscmd.1


:wscmd.2


if defined wscmd.debug call :wscmd.version>&2


:: Lookup and read a configuration file
call :wscmd.ini

:: Set defaults
if not defined wscmd.ini.session-reload set wscmd.ini.session-reload=65535
if not defined wscmd.ini.session-renew set wscmd.ini.session-renew=65534
if not defined wscmd.ini.include set wscmd.ini.include="%~dp0js\*.js" "%~dp0js\win32\*.js" "%~dp0vbs\win32\*.vbs"
if not defined wscmd.ini.execute set "wscmd.ini.execute=%TEMP%\$$$%~n0_$UID.wsf"
if not defined wscmd.ini.command set wscmd.ini.command=%WINDIR%\system32\cscript.exe //NoLogo
if not defined wscmd.ini.xml-encoding set wscmd.ini.xml-encoding=utf-8
if not defined wscmd.ini.enable-error set wscmd.ini.enable-error=false
if not defined wscmd.ini.enable-debug set wscmd.ini.enable-debug=false

:: Check imports
if defined wscmd.noimport set wscmd.ini.include=


:: Make the program name unique
call :wscmd.execute


:: Compile and link the source with libraries
call :wscmd.compile > "%wscmd.execute%"


:: Exit on /compile or /embed
if defined wscmd.compile goto wscmd.stop

if defined wscmd.debug echo.Running:>&2
%wscmd.ini.command% "%wscmd.execute%" %wscmd.args%

:: Reread the ini-file and reload the script in the current session
if !errorlevel! == !wscmd.ini.session-reload! goto wscmd.start

:: Remove the script
if exist "%wscmd.execute%" del "%wscmd.execute%"

:: Rereead the ini-file and reload the script in new session
if !errorlevel! == !wscmd.ini.session-renew! (
	set wscmd.execute=
	goto wscmd.start
)


:wscmd.stop
endlocal
goto :EOF


:wscmd.unquote
if !%1! == "" set %1=" "
if defined %1 set %1=!%1:~1,-1!
if defined %1 set %1=!%1:""="!
goto :EOF


:wscmd.engine
set wscmd.engine=javascript
if /i "%~x1" == ".vbs" set wscmd.engine=vbscript
goto :EOF


:wscmd.version
echo.%wscmd.name% Version %wscmd.version%
goto :EOF


:wscmd.help
call :wscmd.version
echo.
echo.%~n0 [/h ^| /help ^| /man]
echo.%~n0 [/compile ^| /embed] [/v var "val"] [/i ^| /q]
echo.%~n0 [/compile ^| /embed] [/v var "val"] [/js ^| /vbs] /e "code"
echo.%~n0 [/compile ^| /embed] [/v var "val"] [/js ^| /vbs] scriptfile
echo.%~n0 [/debug] [/v var "val"] [/i ^| /q] [arguments]
echo.%~n0 [/debug] [/v var "val"] [/js ^| /vbs] /e "code" [arguments]
echo.%~n0 [/debug] [/v var "val"] [/js ^| /vbs] scriptfile [arguments]
echo.
echo.    /h, /help    - Display this help
echo.    /man         - Display the configuration files guide
echo.    /compile     - Compile but not execute. Just store to a temporary file
echo.    /embed       - The same as above but embed external scripts into a file
echo.    /debug       - Output debugging information and execute
echo.    /v var "val" - Assign the value "val" to the variable var, before
echo.                   execution of the program begins
echo.    /i           - Interactive mode
echo.    /q           - The same as /i but in quiet mode
echo.    /js          - Assume a value as a JavaScript
echo.    /vbs         - Assume a value as a VBScript
echo.    /e "code"    - Assume a value as a code to be executed
echo.    /e /n "code" - Apply the code in a loop per each line of file^(s^)
echo.    /e /p "code" - The same as /e /n but print a line also
echo.
echo.Extra options are available with /e /n or /e /p:
echo.    /d file      - Opens the file using the system default
echo.    /u file      - Opens the file as Unicode
echo.    /a file      - Opens the file as ASCII
echo.
echo."/" and "CON" (case-insensitive) are specified for the console. 
echo.Using them allows reading data from the standard input. 
echo.
echo.Extra options are used like /n or /p in the same way
echo.    /begin       - A code will be executed at the very beginning
echo.    /end         - A code will be executed at the very end
echo.    /beginfile   - A code will be executed before a file
echo.    /endfile     - A code will be executed after a file

goto wscmd.stop


:wscmd.man
echo.PREAMBLE
echo.
echo.This page shows how to control a content and behavior of the resulting 
echo.script using configuration files. You can do this using by one of three 
echo.ways. All options described below are common for all of them. 
echo.
echo.1.  Create the "%~n0.ini" file in the same directory where "%~nx0" is 
echo.    located. This file is common and it will be used in all other cases. 
echo.    That means that it will affect on all scripts always if other ways 
echo.    are not used. 
echo.
echo.2.  Create the "%~n0.ini" file in the current directory where some script 
echo.    will be launched. This file will affect on all files launched from the 
echo.    current directory only. 
echo.
echo.3.  Create the "SCRIPT.ini" file nearby the SCRIPT file (where SCRIPT stands 
echo.    for both the name and the extension of the current file). This file will 
echo.    affect on the SCRIPT file only. 
echo.
echo.SYNTAX
echo.
echo.There are documented options available in ini-files. The syntax for all 
echo.options is common and looks like below:
echo.
echo.    name=value
echo.
echo.You are able to use them in any order but it is recommended to group them 
echo.and use as described below:
echo.
echo.import
echo.    This option specifies a path to librarian files that will be linked to 
echo.    the resulting script. Placeholders "*" or "?" are available to specify 
echo.    a group of files. Environment variables are enabled. In addition, you 
echo.    can use the following modifiers to refer to librarian files relatively 
echo.    the location of "%~nx0". Other modifiers are available but useless. 
echo.
echo.    %%~d0 - means a drive letter
echo.    %%~p0 - means a path only
echo.
echo.    There is special value "import=no" that suppresses inclusion of files. 
echo.    Just write out it directly in a custom configurational file to suppress 
echo.    inclusion of files. 
echo.
echo.execute
echo.    This option defines a name of the resulting file. If it is not specially 
echo.    specified, the default value will be used. There are two placeholders 
echo.    $TIME, the current time, and $UID, the unique number generated by 
echo.    the program, to make the resulting filename unique. 
echo.
echo.command
echo.    This option specifies a binary executable file that will be invoked to 
echo.    launch a script. 
echo.
echo.xml-encoding
echo.    A string that describes the character set encoding used by the resulting 
echo.    XML document. The string may include any of the character sets supported 
echo.    by Microsoft Internet Explorer. The default value is utf-8. 
echo.
echo.enable-error
echo.    A Boolean value. False is the default value. Set to true to allow error 
echo.    messages for syntax or run-time errors in the resulting.wsf file. 
echo.
echo.enable-debug
echo.    A Boolean value. False is the default value. Set to true to enable 
echo.    debugging. If debugging is not enabled, you will be unable to launch 
echo.    the script debugger for a Windows Script file.
echo.
echo.EXAMPLE
echo.
echo.The following example orders to add all js-files and vbs-files relatively 
echo.the directory where "%~nx0" was run. The name of the executed script 
echo.will be created in the current directory with the specified filename. 
echo.The launcher is "CSCRIPT.EXE" with the suppressed banner. 
echo.
echo.    import=%%~dp0\js\*.js
echo.    import=%%~dp0\vbs\*.vbs
echo.    execute=.\$$$%%~n0_$UID.wsf
echo.    command=%%windir%%\system32\cscript.exe //nologo

goto wscmd.stop


:wscmd.ini
:: Load settings from ini-files
:: there are special macros available to be substituted
:: %~d0 - the disk
:: %~p0 - the path
:: %~n0 - the filename
:: %~x0 - the extension
set wscmd.noimport=
set wscmd.ini.include=
set wscmd.ini.execute=
set wscmd.ini.command=
set wscmd.inifiles=".\%~n0.ini" "%~dpn0.ini"
if not defined wscmd.inline set wscmd.inifiles="!wscmd.script!.ini" ".\%~n0.ini" "%~dpn0.ini"
for %%i in ( !wscmd.inifiles! ) do (
	if not "%%~ni" == "" if exist "%%~i" (
		if defined wscmd.debug echo.Configuring from "%%~i">&2
		for /f "usebackq tokens=1,* delims==" %%k in ( "%%~i" ) do (
			call set wscmd.temp=%%~l
			if defined wscmd.temp (
				if /i "%%k" == "import" (
					if /i "!wscmd.temp!" == "no" (
						set wscmd.noimport=1
					) else (
						set wscmd.ini.include=!wscmd.ini.include! "!wscmd.temp!"
					)
				) else (
					set wscmd.ini.%%k=!wscmd.temp!
				)
			)
		)
		goto :EOF
	)
)
goto :EOF


:wscmd.execute
if defined wscmd.execute goto :EOF

set wscmd.execute=%wscmd.ini.execute%

setlocal

set POSH=
call :wscmd.execute.find.powershell powershell.exe
set WMIC=%windir%\System32\Wbem\wmic.exe
set GREP=%windir%\System32\findstr.exe
set FIND=%windir%\System32\find.exe

echo %wscmd.execute% | %FIND% "$TIME">nul 2>&1 && call :wscmd.execute.time
echo %wscmd.execute% | %FIND% "$UID">nul 2>&1 && call :wscmd.execute.uid

endlocal && set wscmd.execute=%wscmd.execute%
goto :EOF


:wscmd.execute.find.powershell
set "POSH=%~$PATH:1"
goto :EOF


:wscmd.execute.time
if defined POSH (
	for /f %%d in ( '%POSH% -Command "Get-Date -UFormat '%%H%%M%%S'" ^<nul' ) do (
		set "wscmd.execute=!wscmd.execute:$TIME=%%d!"
	)
	goto :EOF
)

for /f "tokens=1,2 delims==" %%i in (
	'%WMIC% path win32_localtime get Hour^,Minute^,Second /value ^| %GREP% /v "^$"'
) do (
	set wscmd.time.%%i=00%%j
	set wscmd.time.%%i=!wscmd.time.%%i:~-3,-1!
)

set wscmd.execute=!wscmd.execute:$TIME=%wscmd.time.Hour%%wscmd.time.Minute%%wscmd.time.Second%!
goto :EOF


:wscmd.execute.uid
if defined POSH (
	for /f %%p in ( '
		%POSH% -Command "$p = (Get-WmiObject Win32_Process -Filter ProcessId=$pid).ParentProcessId; (Get-WmiObject Win32_Process -Filter ProcessId=$p).ParentProcessId" ^<nul
	' ) do (
		set "wscmd.execute=!wscmd.execute:$UID=%%p!"
	)
	goto :EOF
)

:wscmd.execute.uid.loop
	rem delims is "=", ";", TAB, WS
	for /f "skip=5 tokens=1,2 delims==;	 " %%a in (
		'%WMIC% Process call create "%windir%\System32\wscript.exe //b" 2^>nul'
	) do if "%%~a" == "ProcessId" (
		set wscmd.uid=%%b
	)

	set wscmd.tmpfile=!wscmd.execute:$UID=%wscmd.uid%!
if exist "!wscmd.tmpfile!" goto wscmd.execute.uid.loop

set wscmd.execute=%wscmd.tmpfile%
goto :EOF


:wscmd.compile
echo.^<?xml version="1.0" encoding="%wscmd.ini.xml-encoding%" ?^>
echo.
echo.^<package^>
echo.^<job id="wscmd"^>
echo.^<?job error="%wscmd.ini.enable-error%" debug="%wscmd.ini.enable-debug%" ?^>
echo.
echo.^<runtime^>
echo.^<description^>^<^^^![CDATA[Created by %wscmd.name% Version %wscmd.version%
echo.%wscmd.copyright%
echo.]]^>^</description^>
echo.^</runtime^>

if not defined wscmd.compile (
echo.^<script language="javascript"^>^<^^^![CDATA[
echo.
echo.new ActiveXObject^('Scripting.FileSystemObject'^).DeleteFile^('!wscmd.execute:\=\\!'^);
echo.
echo.]]^>^</script^>
)

echo.^<script language="javascript"^>^<^^^![CDATA[
echo.
echo.var help = usage = function^(^)
echo.{
echo.	WScript.Arguments.ShowUsage^(^);
echo.};
echo.
echo.var alert = echo = print = ^(function^(^)
echo.{
echo.	var slice = Array.prototype.slice;
echo.	return function^(^)
echo.	{
echo.		WScript.Echo^(slice.call^(arguments^)^);
echo.	};
echo.}^)^(^);
echo.
echo.var quit = exit = function^(exitCode^)
echo.{
echo.	WScript.Quit^(exitCode^);
echo.};
echo.
echo.var cmd = shell = function^(^)
echo.{
echo.	var shell = new ActiveXObject^('WSCript.Shell'^);
echo.	shell.Run^('%%COMSPEC%%'^);
echo.};
echo.
echo.var sleep = function^(time^)
echo.{
echo.	return WScript.Sleep^(time^);
echo.};
echo.
echo.var clip = function^(^)
echo.{
echo.	return new ActiveXObject^('htmlfile'^).parentWindow.clipboardData.getData^('Text'^);
echo.};
echo.
echo.var gc = CollectGarbage;
echo.
echo.var cArgs = WScript.Arguments;
echo.var nArgs = WScript.Arguments.Named;
echo.var uArgs = WScript.Arguments.Unnamed;
echo.
echo.]]^>^</script^>

if defined wscmd.debug echo.Libraries:>&2

set wscmd.link=include
if "%wscmd.compile%" == "2" set wscmd.link=embed

setlocal
for %%l in ( !wscmd.ini.include! ) do (
	if defined wscmd.debug echo.    "%%~l">&2
	call :wscmd.engine "%%~l"
	call :wscmd.%wscmd.link% "%%~l"
)
endlocal

if defined wscmd.var (
	if defined wscmd.debug (
		echo.Variables:
		echo.    !wscmd.var!
	)>&2

echo.^<script language="javascript"^>^<^^^![CDATA[
echo.
echo.!wscmd.var!;
echo.
echo.]]^>^</script^>
)

if defined wscmd.inproc (
	rem wscmd ... /e ... "string" ...
	call :wscmd.inproc
) else if defined wscmd.inline (
	rem wscmd ... /e "string" ...
	call :wscmd.inline
) else if defined wscmd.script (
	rem wscmd ... "filename" ...
	if defined wscmd.debug echo.File: "!wscmd.script!">&2
	call :wscmd.%wscmd.link% "!wscmd.script!"
) else (
	rem Console mode, no inline scripts and no script files
	rem wscmd
	call :wscmd.%wscmd.link% "%~dpnx0"
)

echo.^</job^>
echo.^</package^>
goto :EOF


:wscmd.include
set "wscmd.filename=%~f1"
set "wscmd.filename=%wscmd.filename:&=&amp;%"
echo.^<script language="%wscmd.engine%" src="%wscmd.filename%"^>^</script^>
goto :EOF


:wscmd.embed
echo.^<^^^!-- "%~1" --^>
echo.^<script language="%wscmd.engine%"^>^<^^^![CDATA[
echo.
type "%~1"
echo.
echo.]]^>^</script^>
goto :EOF


:wscmd.inline
if defined wscmd.debug (
	echo.Inline:
	echo.    !wscmd.script!
)>&2
echo.^<script language="%wscmd.engine%"^>^<^^^![CDATA[
echo.
echo.!wscmd.script!
echo.
echo.]]^>^</script^>
goto :EOF


:wscmd.inproc
if defined wscmd.debug (
	echo.Inline:
	if defined wscmd.script.begin  echo.    !wscmd.script.begin!
	echo.    for each file
	if defined wscmd.script.beginfile echo.      !wscmd.script.beginfile!
	echo.      while not EOF
	if defined wscmd.script.n      echo.        !wscmd.script.n!
	if defined wscmd.script.p      echo.        !wscmd.script.p!
	if defined wscmd.script.p      echo.        print line
	echo.      end while
	if defined wscmd.script.endfile  echo.      !wscmd.script.endfile!
	echo.    end for
	if defined wscmd.script.end    echo.    !wscmd.script.end!
)>&2
call :wscmd.inproc.%wscmd.engine%
setlocal
set wscmd.engine=javascript
call :wscmd.%wscmd.link% "%~dpnx0"
endlocal
goto :EOF


:wscmd.inproc.javascript
echo.^<script language="javascript"^>^<^^^![CDATA[
echo.
echo.//@cc_on
echo.//@set @user_inproc_mode = 2
echo.
echo.var userFunc = function^(line, currentNumber, filename, lineNumber, fso, stdin, stdout, stderr^)
echo.{
if defined wscmd.script.n (
echo.	!wscmd.script.n!;
)
if defined wscmd.script.p (
echo.	!wscmd.script.p!;
echo.	if ^( line ^^^!== void 0 ^) {
echo.		WScript.StdOut.WriteLine^(line^);
echo.	}
)
echo.};
echo.
echo.var userFuncBegin = function^(lineNumber, fso, stdin, stdout, stderr^)
echo.{
echo.	!wscmd.script.begin!;
echo.};
echo.
echo.var userFuncEnd = function^(lineNumber, fso, stdin, stdout, stderr^)
echo.{
echo.	!wscmd.script.end!;
echo.};
echo.
echo.var userFuncBeginfile = function^(currentNumber, filename, lineNumber, fso, stdin, stdout, stderr^)
echo.{
echo.	!wscmd.script.beginfile!;
echo.};
echo.
echo.var userFuncEndfile = function^(currentNumber, filename, lineNumber, fso, stdin, stdout, stderr^)
echo.{
echo.	!wscmd.script.endfile!;
echo.};
echo.
echo.]]^>^</script^>
goto :EOF


:wscmd.inproc.vbscript
echo.^<script language="javascript"^>^<^^^![CDATA[
echo.
echo.//@cc_on
echo.//@set @user_inproc_mode = 1
echo.
echo.function Var^(name, value^)
echo.{
echo.	this[name] = value;
echo.};
echo.
echo.]]^>^</script^>
echo.^<script language="vbscript"^>^<^^^![CDATA[
echo.
echo.Sub userFunc^(line, currentNumber, filename, lineNumber, fso, stdin, stdout, stderr^)
if defined wscmd.script.n (
echo.	!wscmd.script.n!
)
if defined wscmd.script.p (
echo.	!wscmd.script.p!
echo.	If Not IsEmpty^(line^) Then
echo.		WScript.StdOut.WriteLine line
echo.	End If
)
echo.End Sub
echo.
echo.Sub userFuncBegin^(lineNumber, fso, stdin, stdout, stderr^)
echo.	!wscmd.script.begin!
echo.End Sub
echo.
echo.Sub userFuncEnd^(lineNumber, fso, stdin, stdout, stderr^)
echo.	!wscmd.script.end!
echo.End Sub
echo.
echo.Sub userFuncBeginfile^(currentNumber, filename, lineNumber, fso, stdin, stdout, stderr^)
echo.	!wscmd.script.beginfile!
echo.End Sub
echo.
echo.Sub userFuncEndfile^(currentNumber, filename, lineNumber, fso, stdin, stdout, stderr^)
echo.	!wscmd.script.endfile!
echo.End Sub
echo.
echo.]]^>^</script^>
goto :EOF


@goto:eof */


(function()
{
//@cc_on
//@if ( ! @user_inproc_mode )
	return;
//@end

//@if ( @user_inproc_mode == 2 )
	var userFunc = this.userFunc;
	var userFuncBegin = this.userFuncBegin;
	var userFuncEnd = this.userFuncEnd;
	var userFuncBeginfile = this.userFuncBeginfile;
	var userFuncEndfile = this.userFuncEndfile;
//@end

	var uc = String.prototype.toUpperCase;

	var fso = new ActiveXObject('Scripting.FileSystemObject');

	var files = WScript.Arguments;
	if ( files.length == 0 ) {
		// Emulate empty list of arguments
		files = ['/'];
		files.item = function(i) { return this[i]; };
	}

	// The number of all lines of all files
	var lineNumber = 0;

	// The function is called before processing any file. 
	// The total number of input lines is 0. 
	userFuncBegin(
		lineNumber, 
		fso, WScript.StdIn, WScript.StdOut, WScript.StdErr);

	var format = 0;
	var file;
	var isFile;
	var stream;

	for (var i = 0; i < files.length; i++) {

		file = files.item(i);

		// Opens the file using the system default
		if ( file == '/D' || file == '/d' ) {
			format = -2;
			continue;
		}

		// Opens the file as Unicode
		if ( file == '/U' || file == '/u' ) {
			format = -1;
			continue;
		}

		// Opens the file as ASCII
		if ( file == '/A' || file == '/a' ) {
			format = 0;
			continue;
		}

		isFile = true;
		if ( file == '/' || uc.call(file) == 'CON' ) {
			file = '<stdin>';
			isFile = false;
		}

		// The number of the current line for the actual file.
		var currentNumber = 0;

		// The function is called before opening of the file. 
		// The file name is known, the number of line of the file is 0. 
		userFuncBeginfile(
			currentNumber, file, lineNumber, 
			fso, WScript.StdIn, WScript.StdOut, WScript.StdErr);

		var e;

		try {
			stream = ! isFile 
				? WScript.StdIn 
				: fso.OpenTextFile(file, 1, false, format);
		} catch (e) {
			WScript.StdErr.WriteLine(e.message + ': ' + file);
			continue;
		}

		// Prevent fail of reading out of STDIN stream
		// The real exception number is 800a005b
		// "Object variable or With block variable not set"
		try {
			stream.AtEndOfStream;
		} catch (e) {
			WScript.StdErr.WriteLine('Out of stream: ' + file);
			continue;
		}

		while ( ! stream.AtEndOfStream ) {

			currentNumber++;
			lineNumber++;
			var line = stream.ReadLine();
			try {
				// Processing of the file. Available parameters are the 
				// current line, it's number in the file, and the number 
				// of the line in the list of all files. 
				userFunc(
					line, currentNumber, file, lineNumber, 
					fso, WScript.StdIn, WScript.StdOut, WScript.StdErr);
			} catch (e) {
				if ( isFile ) {
					stream.Close();
				}
				WScript.StdErr.WriteLine(e.message);
				WScript.Quit();
			}

		} // while

		if ( isFile ) {
			stream.Close();
		}

		// A file processing is completed, and a file is closed already. 
		// The filename and the total number of lines are known. 
		// The currentNumber is the number of lines of the last file. 
		userFuncEndfile(
			currentNumber, file, lineNumber, 
			fso, WScript.StdIn, WScript.StdOut, WScript.StdErr);

	} // for

	// The function will be executed when all files have been processed. 
	// Only lineNumber, the total amount of lines is known. 
	userFuncEnd(
		lineNumber, 
		fso, WScript.StdIn, WScript.StdOut, WScript.StdErr);

	WScript.Quit();
})();

/**
 *
 * Useful functions
 *
 */
var help = usage = (function()
{
	var helpMsg = '\n' 
		+ 'Commands                 Descriptions\n' 
		+ '========                 ============\n' 
		+ 'help(), usage()          Display this help\n' 
		+ 'alert(), echo(), print() Print expressions\n' 
		+ 'quit(), exit()           Quit this shell\n' 
		+ 'eval.history             Display the history\n' 
		+ 'eval.save([format])      Save the history to the file\n' 
		+ 'eval.inspect()           The stub to transform output additionally\n' 
		+ 'cmd(), shell()           Run new DOS-session\n' 
		+ 'sleep(n)                 Sleep n milliseconds\n' 
		+ 'clip()                   Get from the clipboard data formatted as text\n' 
		+ 'reload([true])           Reload this session or open new one\n' 
		+ 'gc()                     Run the garbage collector\n' 
		;
	return function()
	{
		WScript.Echo(helpMsg);
	};
})();

var alert = echo = print = (function()
{
	var slice = Array.prototype.slice;
	return function()
	{
		WScript.Echo(slice.call(arguments));
	};
})();

var quit = exit = function(exitCode)
{
	WScript.Quit(exitCode);
};

var cmd = shell = function()
{
	var shell = new ActiveXObject('WSCript.Shell');
	shell.Run('%COMSPEC%');
};

var sleep = function(time)
{
	return WScript.Sleep(time);
};

var clip = function()
{
	return new ActiveXObject('htmlfile').parentWindow.clipboardData.getData('Text');
};

var reload = function(newSession)
{
	var shell = new ActiveXObject('WScript.Shell');
	var env = shell.Environment('PROCESS');

	var name = newSession ? 'wscmd.ini.session-renew' : 'wscmd.ini.session-reload';
	var code = env(name);

	WScript.Quit(code);
};

var gc = CollectGarbage;

/**
 *
 * Enabled in the CLI mode ONLY
 *
 */
if ( ! WScript.FullName.match(/cscript/i) ) {
	help();
	exit();
}

/**
 *
 * The line number
 *
 */
eval.number = 0;

/**
 *
 * The history of commands
 *
 */
eval.history = '';

eval.save = function(format)
{
	var fso = new ActiveXObject('Scripting.FileSystemObject');

	var f = fso.OpenTextFile('.\\wscmd.history', 8, true, format);
	f.Write(eval.history);
	f.Close();
};

/**
 *
 * The references to the command line arguments
 *
 */
var cArgs = WScript.Arguments;
var nArgs = WScript.Arguments.Named;
var uArgs = WScript.Arguments.Unnamed;

while ( true ) {

	/*
	This is internally used variable for catching run-time errors. We 
	do not try to hide it completely from the user but we do an attempt to 
	complicate its name as much as possible to prevent intersection with 
	user-defined objects. Also we understand that the user can give the 
	same name for its variable. Anyway, it doesn't affect on the script 
	performance. 
	*/
	var __3rr0r__;
	try {

		/*
		The eval function itself
		String containing the result of eval'd string
		*/
		(function(e, result)
		{
			/*
			A user can modify the code of the eval function so 
			to prevent the destruction of this function we have to 
			keep its original code and restore the code later
			*/
			eval = e;

			if ( result === void 0 ) {
				return;
			}
			if ( typeof eval.inspect == 'function' && typeof result == 'object' ) {
				result = eval.inspect(result);
			}
			WScript.Echo(result);
		})
		(eval, eval((function(PS1, PS2)
		{

			var env = new ActiveXObject('WScript.Shell').Environment('PROCESS');
			if ( env('wscmd.quiet') ) {
				PS1 = '';
				PS2 = '';
			} else {
				PS1 = 'wscmd > ';
				PS2 = 'wscmd :: ';
			}

			/*
			The eval.history can be changed by the user as he can. 
			We should prevent a concatenation with the one of 
			the empty values such as undefined, null, etc. 
			*/
			if ( ! eval.history || typeof eval.history != 'string' ) {
				eval.history = '';
			}

			/*
			The eval.number can be changed by the user as he can. 
			We should prevent an incrementing of non-numeric values. 
			*/
			if ( ! eval.number || typeof eval.number != 'number' ) {
				eval.number = 0;
			}

			/*
			Validate that a user started multiple lines ending 
			with the backslash character '\\'. 

			The number of tailing backslashes affects on the 
			behavior of the input. 

			When a user ends a line with the single backslash 
			it will be considered as continuing on next lines 
			until a user enters an empty line. 

			When a user enters a line only with two 
			backslashes then it will be considered as 
			multilinear entering as well. 
			The main difference with the first case is a 
			possibility to enter any number of empty lines. 
			*/
			var multiline = 0;

			/*
			Store all characters entered from STDIN. 

			Array is used to prevent usage of String.charAt that can be 
			overridden. This makes the code the safer. 
			*/
			var result = [];

			WScript.StdOut.Write(PS1);

			while ( true ) {

				// One entered line as an array of characters
				var input = (function()
				{
					var e;
					try {
						eval.number++;
						return (function()
						{
							var result = [];
							while ( ! WScript.StdIn.AtEndOfLine ) {
								result[result.length] = WScript.StdIn.Read(1);
							}
							WScript.StdIn.ReadLine();
							return result;
						})();
					} catch (e) {
						return ['q', 'u', 'i', 't', '(', ')'];
					}
				})();

				if ( input.length == 0 && multiline != 2 ) {
					break;
				}

				if ( input.length == 2 && input[0] + input[1] == '\\\\' ) {
					input.length -= 2;
					multiline = multiline == 2 ? 0 : 2;
				} else if ( input[input.length - 1] == '\\' ) {
					input.length--;
					if ( ! multiline ) {
						multiline = 1;
					}
				}

				// Add the new line character in the multiline mode
				if ( result.length ) {
					result[result.length] = '\n';
				}

				for (var i = 0; i < input.length; i++) {
					result[result.length] = input[i];
				}

				if ( ! multiline ) {
					break;
				}

				WScript.StdOut.Write(PS2);

			} // while ( true )

			// Trim left
			var k = 0;
			while ( result[k] <= ' ' ) {
				k++;
			}
			// Trim right
			var m = result.length - 1;
			while ( result[m] <= ' ' ) {
				m--;
			}

			var history = '';
			for (var i = k; i <= m; i++) {
				history += result[i];
			}
			if ( history == '' ) {
				return '';
			}

			if ( eval.history ) {
				eval.history += '\n';
			}
			eval.history += history;
			return history;

		})()));

	} catch (__3rr0r__) {

		WScript.Echo(WScript.ScriptName + ': "<stdin>", line ' + eval.number + ': ' + __3rr0r__.name + ': ' + __3rr0r__.message);

	}

}

WScript.Quit();

