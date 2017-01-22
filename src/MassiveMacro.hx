package;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import tink.macro.ClassBuilder;
import tink.macro.Member;
import haxe.macro.Type.MetaAccess;
import tink.SyntaxHub;
using tink.MacroApi;
#end

class MassiveMacro{

#if macro

  public static function use(){

    function appliesTo(m:MetaAccess) return m.has('mass') || m.has(':mass');
		
		SyntaxHub.classLevel.after(
			function (_) return true,
			function (c:ClassBuilder) {
				if (c.target.isInterface) return false;
        applyTo(c);
        //trace('>>> ${c.target.name}');
        return appliesTo(c.target.meta);
			}
		);
  }

  public static function isMassive(s:String) return s == 'mass' || s == ':mass';

	public static function applyTo(cb:ClassBuilder){
		for (member in cb) processMember(member);
	}
	
	public static function transform(f:Function, ?name:String): Function {
		var processed = (new FunctionTransformer(f)).transform();
		#if massive_debug
      trace('=======================');
      trace(name);
      trace('=======================');
		#end
		return processed;
	}
	
	public static function processMember(member:Member) {
		var field:Field = member;
		switch member.getFunction() {
			case Success(func):
				if (field.meta != null) for (meta in field.meta) {
          if (isMassive(meta.name)) {
            field.kind = FieldType.FFun(transform(func, field.name));
          }
        }
			default:
		}
	}

  private static function extractFields(x:Expr){
    trace(Context.currentPos());
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

  public static function massiveMacro(a:Expr, b:Expr, ?props:Array<String>){
    props = (props == null || props.length == 0) ? extractFields(a) : props;

    var aID:String = extrIdentifier(a);
    var bID:String = extrIdentifier(b);
    var code = '{\n' + [for(p in props) '$aID.$p = $bID.$p;'].join('\n') + '}';
    return Context.parse(code, Context.currentPos());
  }

#end

  public static macro function massive(a:Expr, b:Expr, ?props:Array<String>){
    return massiveMacro(a,b,props);
  }

}
