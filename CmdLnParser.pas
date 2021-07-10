{*  Program command line options parser implementation.

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
        1.0.0 2021-06-28 jrgdre, initial release
}
unit CmdLnParser;
{$mode Delphi}
{$modeSwitch advancedRecords}

interface

uses
	classes;

type
	{! Recognized command line argument expectations.
	}
	TCmdLnArgOpt = (
		claoNoArgument      , //!< no argument expected
		claoOptionalArgument, //!< an argument is optional
		claoRequiredArgument  //!< an argument is required
	);

	{! Command line option declaration data type.
	}
	TCmdLnOption = record
		Name  : String;			//!< Options name (e.g. '-h')
		ArgOpt: TCmdLnArgOpt;	//!< Argument expectation
		procedure SetOpt(const aName: String; const aArgOpt: TCmdLnArgOpt);
		procedure Reset;
	end;
	TCmdLnOptions = array of TCmdLnOption;

	{! Parser event call back function declaration.
	}
	TCmdLnParserCallBack = procedure(
		const optIdx: Integer; //!< Idx of option found (-1 on error)
		const optArg: String ; //!< Argument found for option (if any)
		  var cancel: Boolean; //!< Set to True, if parsing should be canceled
		const ptr   : Pointer  //!< User defined pointer (transfered from Parse())
	);

{! Parse the process's command line options.
}
function Parse(
	const options : TCmdLnOptions;		  //!< Users' cmd ln options declaration
	const callback: TCmdLnParserCallBack; //!< User provided call back for parser events
	const ptr     : Pointer				  //!< User defined pointer (transfered to call-back)
): Boolean;

implementation

uses
	regexpr;

var
	regEx: TRegExpr;

procedure TCmdLnOption.SetOpt(
	const aName  : String;
	const aArgOpt: TCmdLnArgOpt
);
begin
	Name   := aName;
	ArgOpt := aArgOpt;
end;

procedure TCmdLnOption.Reset;
begin
	Name   := '';
	ArgOpt := claoNoArgument;
end;

function FindOpt(
	const param : String;
	const opts  : TCmdLnOptions;
	  var optIdx: Integer;
	  var optArg: String
): Boolean;
var
	i: Integer;
begin
	Result := False;
	for i := Low(opts) to High(opts) do begin
		regEx.Expression := '^' + opts[i].Name;
		if regEx.Exec(param) then begin
			optIdx := i;
			regEx.Expression := '(=)([\S]+)';
			if regEx.Exec(param) then
				optArg := regEx.Match[2];
			Result := True;
			Exit;
		end;
	end;
end;

function Parse(
	const options : TCmdLnOptions;
	const callback: TCmdLnParserCallBack;
	const ptr     : Pointer
): Boolean;
var
	i     : Integer;
	optArg: String;
	optIdx: Integer;
	param : String;
	cancel: Boolean;
begin
	Result := True;
	i      := 1;
	while (i <= ParamCount) do begin
		param := ParamStr(i);
		optIdx := 0;
		optArg := '';
		if not FindOpt(param, options, optIdx, optArg) then
			callback(-1, param, cancel, ptr) // expected option, found <param>
		else
			callback(optIdx, optArg, cancel, ptr);
		if cancel then begin
		  	Result := False;
			Exit;
		end;
		Inc(i);
	end;
end;

initialization

	regEx := TRegExpr.Create;

finalization

	regEx.Free;

end.
