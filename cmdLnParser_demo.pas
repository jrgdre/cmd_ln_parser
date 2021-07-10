{!  Program command line options parser, demo application.

    @copyright
        (c)2021 Medical Data Solutions GmbH, www.medaso.de

    @license
        MIT:
            Permission is hereby granted, free of charge, to any person
            obtaining a copy of this software and associated documentation files
            (the "Software"), to deal in the Software without restriction,
            including without limitation the rights to use, copy, modify, merge,
            publish, distribute, sublicense, and/or sell copies of the Software,
            and to permit persons to whom the Software is furnished to do so,
            subject to the following conditions:

            The above copyright notice and this permission notice shall be
            included in all copies or substantial portions of the Software.

    @author
        jrgdre: J.Drechsler, Medical Data Solutions GmbH

    @version
        1.0.0 2021-07-08 jrgdre, initial release
}
program cmdLnParser_demo;
{$mode Delphi}

uses
    CmdLnParser,
    classes,
    sysutils;

type
    TOptions = record
        HasOptInput       : Boolean;
        HasArgInput       : Boolean;
        ArgInput          : String;
        HasOptOutput      : Boolean;
        HasArgOutput      : Boolean;
        ArgOutput         : String;
        HasOptHelp        : Boolean;
		HasOptQuiet       : Boolean;
		//
		ParserErrors: TStringList;
    end;
	POptions = ^TOptions;


const
	TITLE    : String = 'cmdLnParser_demo';
	VERSION  : String = '2021.07.00.0000';
	COPYRIGHT: String = '(c)2021 Medical Data Solutions GmbH, MIT license.';

{!	Command line parser event handler.

	Implementation is greedy. It returns `cancel` as false, even in case of an
	error. This allows to find as many cmd line errors as possible.
}
procedure CmdLnParserCallBack(
	const optIdx: Integer;
	const optArg: String;
	  var cancel: Boolean;
	const ptr   : Pointer
);
begin
	cancel  := False;
	with POptions(ptr)^ do begin
		case optIdx of
			0,1: begin
				HasOptInput := True;
				HasArgInput := Length(optArg) > 0;
				ArgInput    := optArg;
			end;
			2,3: begin
				HasOptOutput := True;
				HasArgOutput := Length(optArg) > 0;
				ArgOutput    := optArg;
			end;
			4,5: begin
				HasOptHelp := True;
			end;
			6,7: begin
				HasOptQuiet := True;
			end;
			else begin
				ParserErrors.Add(
                    Format(
						'command error: expected option, found %s',
                    	[QuotedStr(optArg)]
					)
				);
			end;
		end;
	end;
end;

function ValidateOpts(var opts: TOptions): Boolean;
begin
	Result := True;
	with opts do begin
		if HasOptOutput and (not HasArgOutput) then begin
			ParserErrors.Add(
				'option `--output` missing mandatory argument'
				+' (see cmdLnParser_demo -h)'
			);
			Result := False;
		end;
	end;
end;

function ParseCmdLn(var options: TOptions): Boolean;
var
	cmdLnOpts: TCmdLnOptions;
begin
	SetLength(cmdLnOpts, 8);
	cmdLnOpts[0].SetOpt('-i'      , claoOptionalArgument);
	cmdLnOpts[1].SetOpt('--input' , claoOptionalArgument);
	cmdLnOpts[2].SetOpt('-o'      , claoRequiredArgument);
	cmdLnOpts[3].SetOpt('--output', claoRequiredArgument);
	cmdLnOpts[4].SetOpt('-h'      , claoNoArgument      );
	cmdLnOpts[5].SetOpt('--help'  , claoNoArgument      );
	cmdLnOpts[6].SetOpt('-q'      , claoNoArgument      );
	cmdLnOpts[7].SetOpt('--quiet' , claoNoArgument      );

	Result := CmdLnParser.Parse(cmdLnOpts, CmdLnParserCallBack, @options);
end;

procedure PrintBanner;
begin
	WriteLn(Format('%s version %s', [TITLE, VERSION]));
	WriteLn(Format('%s', [COPYRIGHT]));
end;

procedure PrintHelp;
begin
	WriteLn('cmdLnParser_demo usage:');
	WriteLn('$mcg [<options>]');
	WriteLn('<options>:');
	WriteLn('-h');
	WriteLn('--help');
	WriteLn('    print this help');
	WriteLn('-i');
	WriteLn('--input');
	WriteLn('    read input from standard stdIn');
	WriteLn('-i=<file>');
	WriteLn('--input=<file>');
	WriteLn('    read input from <file>');
	WriteLn('-o=<directory>');
	WriteLn('--output=<directory>');
	WriteLn('    write output files to <directory>');
	WriteLn('-q');
	WriteLn('--quiet');
	WriteLn('    do not print banner');
end;

var
	err   : Boolean;
	errStr: String;
	opts  : TOptions;
begin
	opts.ParserErrors := TStringList.Create;
	try
		opts.ParserErrors.StrictDelimiter := True;

		err := (not ParseCmdLn(opts))			// call back returned false
		    or (not ValidateOpts(opts))         // validation failed
			or (opts.ParserErrors.Count > 0);	// error(s) reported

		if not opts.HasOptQuiet then
			PrintBanner;

		with opts do begin
			Write('HasOptInput  : '); WriteLn(HasOptInput );
			Write('HasArgInput  : '); WriteLn(HasArgInput );
			Write('ArgInput     : '); WriteLn(ArgInput    );
			Write('HasOptOutput : '); WriteLn(HasOptOutput);
			Write('HasArgOutput : '); WriteLn(HasArgOutput);
			Write('ArgOutput    : '); WriteLn(ArgOutput   );
			Write('HasOptHelp   : '); WriteLn(HasOptHelp  );
			Write('HasOptQuiet  : '); WriteLn(HasOptQuiet );
			Write('Parser errors: '); WriteLn(ParserErrors.Count);
			for errStr in ParserErrors do
				WriteLn(errStr);
		end;

		if opts.HasOptHelp then begin
			PrintHelp;
			ExitCode := 0;
			Exit;
		end;

		if err then begin
			WriteLn(TITLE+' exits with errors, try -h option for help.');
			ExitCode := -1;
			Exit;
		end;

		// start normal program execution

	finally
		opts.ParserErrors.Free;
	end;
end.
