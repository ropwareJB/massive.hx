package massive;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.ClassBuilder;
import tink.macro.Member;
import haxe.macro.Type.MetaAccess;
import tink.SyntaxHub;
using tink.MacroApi;
using Lambda;
#end

typedef MassContext = {
  var scenario:Array<String>;
}

class MassiveMacro{

#if macro
  private static var context:MassContext;

  public static function use(){
    context = {scenario:[]};
		SyntaxHub.exprLevel.inward.whenever(new ExpressionTransformerInward(context));
		SyntaxHub.exprLevel.outward.whenever(new ExpressionTransformerOutward(context));
  }

  inline private static function shouldExtractField(f):Bool{
    return switch(f.kind){
      case FVar(r,w): f.isPublic && (w == AccNormal || w == AccCall);
      default: false;
    }
  }
	
  private static function extractFields(x:Expr):Array<String>{
    var x_type = Context.typeof(x);
    switch(x_type){
      case TInst(class_t, params):
        return [ for(f in class_t.get().fields.get()) if(shouldExtractField(f)) f.name ];
      default: 
         var e = 'Massive Assignment Error: Object instance expected instead of $x_type';
         return Context.error(e, x.pos);
    }
  }

  private static function extrIdentifier(a:Expr):String{
    switch(a.expr){
      case EConst(CIdent(x)): return '$x';
      default:
        return Context.error('Object identifier expected instead of $a',a.pos);
    }
  }

  private static function mapStatic(a:Expr, b:Expr, props:Array<String>):Expr{
    var aID:String = extrIdentifier(a);
    var bID:String = extrIdentifier(b);
    var code = '{\n' + [for(p in props) '$aID.$p = $bID.$p;'].join('\n') + '}';
    return Context.parse(code, Context.currentPos());
  }

  private static function mapDynamic(a:Expr, b:Expr, props:Expr):Expr{
    return @:pos(a.pos) macro { 
      for(p in $props)
        Reflect.setProperty($a, p, Reflect.getProperty($b, p));
    };
  }

  private static function arrayOfStrings(xs:Array<Expr>):Bool{
    for(x in xs){
      return switch x.expr{
        case EConst(CString(x)): continue;
        default: return false;
      };
    }
    return true;
  }

  private static function invReificateArray(xs:Array<Expr>):Array<String>{
    return xs.map(function(x:Expr){
      switch x.expr{
        case EConst(CString(y)): return '$y';
        default: 
          Context.error("MASSIVE_MACRO_FAIL - inverse reification.", x.pos);
          return "";
      }
    });
  }

  public static function massiveMacro(a:Expr, b:Expr, ?props:Expr):Expr{
    switch(props.expr){
      case EArrayDecl([]): 
        var str_props = extractFields(a);
        return mapStatic(a, b, str_props);
      case EArrayDecl(xs):
        if(arrayOfStrings(xs)) return mapStatic(a, b, invReificateArray(xs));
        else return mapDynamic(a,b,props);
      default: 
        return mapDynamic(a, b, props);
    }
  }

#end

  public static macro function massAssign(a:Expr, b:Expr, ?props:Expr){
    return massiveMacro(a,b,props);
  }

}
