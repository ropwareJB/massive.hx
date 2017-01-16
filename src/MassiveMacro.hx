package;

import haxe.macro.Context;
import haxe.macro.Expr;

class MassiveMacro{

  public static macro function massive(a:Expr, b:Expr, ?props:Array<String>){
    props = (props == null) ? extractFields(a) : props;

    var aID:String = extrIdentifier(a);
    var bID:String = extrIdentifier(b);
    var code = '{\n' + [for(p in props) '$aID.$p = $bID.$p;'].join('\n') + '}';
    return Context.parse(code, Context.currentPos());
  }

#if macro
  private static function extractFields(x:Expr){
    var x_type = Context.typeof(x);
    switch(x_type){
      case TInst(class_t, params):
         return [ for(f in class_t.get().fields.get()) f.name ];
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
#end

}
