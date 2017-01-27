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
	
  private static function extractFields(x:Expr):Expr{
    var x_type = Context.typeof(x);
    switch(x_type){
      case TInst(class_t, params):
        var x = [ for(f in class_t.get().fields.get()) if(shouldExtractField(f)) f.name ];
        return macro $v{x};
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

  public static function massiveMacro(a:Expr, b:Expr, ?props:Expr):Expr{
    props = switch(props.expr){
      case EArrayDecl([]): extractFields(a);
      case EArrayDecl(ys):
          trace(ys);
          props;
      default: props;
    }
    props = (props == null) ? extractFields(a) : props;
    var aID:String = extrIdentifier(a);
    var bID:String = extrIdentifier(b);
    return @:pos(a.pos) macro { 
      for(p in $props)
        Reflect.setProperty($a, p, Reflect.getProperty($b, p));
    };
  }

#end

  public static macro function massAssign(a:Expr, b:Expr, ?props:Expr){
    return massiveMacro(a,b,props);
  }

}
