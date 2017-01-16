package;

import haxe.macro.Context;
import haxe.macro.Expr;

class ExampleModel{

  public var propertyA:Int;
  public var propertyB:Int;

  public function new(a:Int,b:Int){
    this.propertyA = a;
    this.propertyB = b;
  }

}

@:final class Main{

	public static function main():Void{
    var oldModel = new ExampleModel(1, 2);
    var newModel = new ExampleModel(3, 4);

    // How I want it to end up looking?
    //@massive(propertyA) oldModel = newModel;
    massive(oldModel, newModel, ["propertyA"]);

    trace('Old propertyA: ${oldModel.propertyA}');
    trace('Old propertyB: ${oldModel.propertyB}');
	}

  public static macro function massive(a:Expr, b:Expr, props:Array<String>){
    var aID = extrIdentifier(a);
    var bID = extrIdentifier(b);
    var code = '{\n' + [for(p in props) '$aID.$p = $bID.$p;'].join('\n') + '}';
    return Context.parse(code, Context.currentPos());
  }
  
#if macro
  private static function extrIdentifier(a:Expr){
    switch(a.expr){
      case EConst(CIdent(x)): return '$x';
      default:
        return Context.error('Object identifier expected instead of $a',a.pos);
    }
  }
#end

}
