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
	
  private static function extractFields(x:Expr, ?scenario:String){
    var x_type = Context.typeof(x);
    switch(x_type){
      case TInst(class_t, params):
         return [ for(f in class_t.get().fields.get()) if(shouldExtractField(f)) f.name ];
      default: 
         var e = 'Massive Assignment Error: Object instance expected instead of $x_type';
         return Context.error(e, x.pos);
    }
  }

  private static function extrIdentifier(a:Expr){
    switch(a.expr){
      case EConst(CIdent(x)): return '$x';
      default:
        return Context.error('Object identifier expected instead of $a',a.pos);
    }
  }

  public static function massiveMacro(a:Expr, b:Expr, ?props:Array<String>, ?scenario:String){
    props = (props == null || props.length == 0) ? extractFields(a, scenario) : props;

    var aID:String = extrIdentifier(a);
    var bID:String = extrIdentifier(b);
    var code = '{\n' + [for(p in props) '$aID.$p = $bID.$p;'].join('\n') + '}';
#if massive_debug
    trace("##########");
    trace(code);
    trace("##########");
#end
    return Context.parse(code, Context.currentPos());
  }

#end

  public static macro function massAssign(a:Expr, b:Expr, ?props:Array<String>, ?scenario:String){
#if massive_debug
    trace('Mass assigning under scenario "$scenario"...');
#end
    return massiveMacro(a,b,props,scenario);
  }

}
