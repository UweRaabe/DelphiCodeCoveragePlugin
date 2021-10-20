{---------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with the
License. You may obtain a copy of the License at
http://www.mozilla.org/NPL/NPL-1_1Final.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: mwSimplePasParTypes, released November 14, 1999.

The Initial Developer of the Original Code is Martin Waldenburg
unit CastaliaPasLexTypes;

----------------------------------------------------------------------------}

unit CodeCoverage.SimpleParser.Types;

interface

uses
  SysUtils,
  TypInfo;

type
  TmwParseError = (
    InvalidAdditiveOperator,
    InvalidAccessSpecifier,
    InvalidCharString,
    InvalidClassMethodHeading,
    InvalidConstantDeclaration,
    InvalidConstSection,
    InvalidDeclarationSection,
    InvalidDirective16Bit,
    InvalidDirectiveBinding,
    InvalidDirectiveCalling,
    InvalidExportedHeading,
    InvalidForStatement,
    InvalidInitializationSection,
    InvalidInterfaceDeclaration,
    InvalidInterfaceType,
    InvalidLabelId,
    InvalidLabeledStatement,
    InvalidMethodHeading,
    InvalidMultiplicativeOperator,
    InvalidNumber,
    InvalidOrdinalIdentifier,
    InvalidParameter,
    InvalidParseFile,
    InvalidProceduralDirective,
    InvalidProceduralType,
    InvalidProcedureDeclarationSection,
    InvalidProcedureMethodDeclaration,
    InvalidRealIdentifier,
    InvalidRelativeOperator,
    InvalidStorageSpecifier,
    InvalidStringIdentifier,
    InvalidStructuredType,
    InvalidTryStatement,
    InvalidTypeKind,
    InvalidVariantIdentifier,
    InvalidVarSection,
    vchInvalidClass,
    vchInvalidMethod,
    vchInvalidProcedure,
    vchInvalidCircuit,
    vchInvalidIncludeFile
  );

  TmwPasCodeInfo = (
    ciNone,
    ciAccessSpecifier,
    ciAdditiveOperator,
    ciArrayConstant,
    ciArrayType,
    ciAsmStatement,
    ciBlock,
    ciCaseLabel,
    ciCaseSelector,
    ciCaseStatement,
    ciCharString,
    ciClassClass,
    ciClassField,
    ciClassForward,
    ciClassFunctionHeading,
    ciClassHeritage,
    ciClassMemberList,
    ciClassMethodDirective,
    ciClassMethodHeading,
    ciClassMethodOrProperty,
    ciClassMethodResolution,
    ciClassProcedureHeading,
    ciClassProperty,
    ciClassReferenceType,
    ciClassType,
    ciClassTypeEnd,
    ciClassVisibility,
    ciCompoundStatement,
    ciConstantColon,
    ciConstantDeclaration,
    ciConstantEqual,
    ciConstantExpression,
    ciConstantName,
    ciConstantValue,
    ciConstantValueTyped,
    ciConstParameter,
    ciConstructorHeading,
    ciConstructorName,
    ciConstSection,
    ciContainsClause,
    ciContainsExpression,
    ciContainsIdentifier,
    ciContainsStatement,
    ciDeclarationSection,
    ciDesignator,
    ciDestructorHeading,
    ciDestructorName,
    ciDirective16Bit,
    ciDirectiveBinding,
    ciDirectiveCalling,
    ciDirectiveDeprecated,
    ciDirectiveLibrary,
    ciDirectiveLocal,
    ciDirectivePlatform,
    ciDirectiveVarargs,
    ciDispIDSpecifier,
    ciDispInterfaceForward,
    ciEmptyStatement,
    ciEnumeratedType,
    ciEnumeratedTypeItem,
    ciExceptBlock,
    ciExceptionBlockElseBranch,
    ciExceptionClassTypeIdentifier,
    ciExceptionHandler,
    ciExceptionHandlerList,
    ciExceptionIdentifier,
    ciExceptionVariable,
    ciExpliciteType,
    ciExportedHeading,
    ciExportsClause,
    ciExportsElement,
    ciExpression,
    ciExpressionList,
    ciExternalDirective,
    ciExternalDirectiveThree,
    ciExternalDirectiveTwo,
    ciFactor,
    ciFieldDeclaration,
    ciFieldList,
    ciFileType,
    ciFormalParameterList,
    ciFormalParameterSection,
    ciForStatement,
    ciForwardDeclaration,
    ciFunctionHeading,
    ciFunctionMethodDeclaration,
    ciFunctionMethodName,
    ciFunctionProcedureBlock,
    ciFunctionProcedureName,
    ciHandlePtCompDirect,
    ciHandlePtDefineDirect,
    ciHandlePtElseDirect,
    ciHandlePtIfDefDirect,
    ciHandlePtEndIfDirect,
    ciHandlePtIfNDefDirect,
    ciHandlePtIfOptDirect,
    ciHandlePtIncludeDirect,
    ciHandlePtResourceDirect,
    ciHandlePtUndefDirect,
    ciIdentifier,
    ciIdentifierList,
    ciIfStatement,
    ciImplementationSection,
    ciIncludeFile,
    ciIndexSpecifier,
    ciInheritedStatement,
    ciInitializationSection,
    ciInlineStatement,
    ciInterfaceDeclaration,
    ciInterfaceForward,
    ciInterfaceGUID,
    ciInterfaceHeritage,
    ciInterfaceMemberList,
    ciInterfaceSection,
    ciInterfaceType,
    ciLabelDeclarationSection,
    ciLabeledStatement,
    ciLabelId,
    ciLibraryFile,
    ciMainUsedUnitExpression,
    ciMainUsedUnitName,
    ciMainUsedUnitStatement,
    ciMainUsesClause,
    ciMultiplicativeOperator,
    ciNewFormalParameterType,
    ciNumber,
    ciNextToken,
    ciObjectConstructorHeading,
    ciObjectDestructorHeading,
    ciObjectField,
    ciObjectForward,
    ciObjectFunctionHeading,
    ciObjectHeritage,
    ciObjectMemberList,
    ciObjectMethodDirective,
    ciObjectMethodHeading,
    ciObjectNameOfMethod,
    ciObjectProcedureHeading,
    ciObjectProperty,
    ciObjectPropertySpecifiers,
    ciObjectType,
    ciObjectTypeEnd,
    ciObjectVisibility,
    ciOldFormalParameterType,
    ciOrdinalIdentifier,
    ciOrdinalType,
    ciOutParameter,
    ciPackageFile,
    ciParameterFormal,
    ciParameterName,
    ciParameterNameList,
    ciParseFile,
    ciPointerType,
    ciProceduralDirective,
    ciProceduralType,
    ciProcedureDeclarationSection,
    ciProcedureHeading,
    ciProcedureMethodDeclaration,
    ciProcedureMethodName,
    ciProgramBlock,
    ciProgramFile,
    ciPropertyDefault,
    ciPropertyInterface,
    ciPropertyName,
    ciPropertyParameterConst,
    ciPropertyParameterList,
    ciPropertySpecifiers,
    ciQualifiedIdentifier,
    ciQualifiedIdentifierList,
    ciRaiseStatement,
    ciReadAccessIdentifier,
    ciRealIdentifier,
    ciRealType,
    ciRecordConstant,
    ciRecordFieldConstant,
    ciRecordType,
    ciRecordVariant,
    ciRelativeOperator,
    ciRepeatStatement,
    ciRequiresClause,
    ciRequiresIdentifier,
    ciResolutionInterfaceName,
    ciResourceDeclaration,
    ciReturnType,
    ciSEMICOLON,
    ciSetConstructor,
    ciSetElement,
    ciSetType,
    ciSimpleExpression,
    ciSimpleStatement,
    ciSimpleType,
    ciSkipAnsiComment,
    ciSkipBorComment,
    ciSkipSlashesComment,
    ciSkipSpace,
    ciSkipCRLFco,
    ciSkipCRLF,
    ciStatement,
    ciStatementList,
    ciStorageExpression,
    ciStorageIdentifier,
    ciStorageDefault,
    ciStorageNoDefault,
    ciStorageSpecifier,
    ciStorageStored,
    ciStringIdentifier,
    ciStringStatement,
    ciStringType,
    ciStructuredType,
    ciSubrangeType,
    ciTagField,
    ciTagFieldName,
    ciTagFieldTypeName,
    ciTerm,
    ciTryStatement,
    ciTypedConstant,
    ciTypeDeclaration,
    ciTypeId,
    ciTypeKind,
    ciTypeName,
    ciTypeSection,
    ciUnitFile,
    ciUnitId,
    ciUsedUnitName,
    ciUsedUnitsList,
    ciUsesClause,
    ciVarAbsolute,
    ciVarEqual,
    ciVarDeclaration,
    ciVariable,
    ciVariableList,
    ciVariableReference,
    ciVariableTwo,
    ciVariantIdentifier,
    ciVariantSection,
    ciVarParameter,
    ciVarSection,
    ciVisibilityAutomated,
    ciVisibilityPrivate,
    ciVisibilityProtected,
    ciVisibilityPublic,
    ciVisibilityPublished,
    ciVisibilityUnknown,
    ciWhileStatement,
    ciWithStatement,
    ciWriteAccessIdentifier
  );

function ParserErrorName(Value: TmwParseError): string;

implementation

function ParserErrorName(Value: TmwParseError): string;
begin
  result := GetEnumName(TypeInfo(TmwParseError), Integer(Value));
end;

end.

