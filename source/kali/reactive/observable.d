module kali.reactive.observable;

import kali.reactive.subscribtion;
import kali.reactive.observer;

import std.functional, std.stdio, std.conv;

private class MapProxyObserver(A,B) : Observer!A {
	private B delegate(A) f;
	private Observer!B observer;
	
	this(B delegate(A) fun, Observer!B o) {
		f = fun;
		observer = o;
	}
	
	override void onEach(A value) {
		observer.onEach(f(value));
	}
	
	override void onComplete() {
		// TODO
	}

	override void onError(Throwable t) {
		// TODO
	}
}

private class FilterProxyObserver(A): Observer!A {
	private bool delegate(A) predicate;
	private Observer!A observer;
	
	this(bool delegate(A) p, Observer!A o) {
		predicate = p;
		observer = o;
	}
	
	override void onEach(A value) {
		if (predicate(value)) {
			observer.onEach(value);
		}
	}
	
	override void onComplete() {
		// TODO
	}

	override void onError(Throwable t) {
		// TODO
	}
}


class Observable(A) {
	private void delegate(Observer!A) onSubscribe;
	
	public this(void delegate(Observer!A) o) {
		onSubscribe = o;
	}
	
	public void subscribe(Observer!A observer) {
		onSubscribe(observer);
	}
	
	private Observable!B delegate(Observable!A) fmap(B)(B delegate(A) f) {
		return (Observable!A observable) {
			Observable!B b = new Observable!B((observer) {
					MapProxyObserver!(A,B) proxyObserver = new MapProxyObserver!(A,B)(f,observer);
					observable.subscribe(proxyObserver);
			});
			return b;
		};
	}
	
	public Observable!B map(B)(B delegate(A) f) {
		return fmap!B(f)(this);
	}
	
	public Observable!A filter(bool delegate(A) p) {
		Observable!A a = new Observable!A((observer) {
				this.subscribe(new FilterProxyObserver!A(p, observer));
		});
		return a;
	}
}

C delegate(A) o(A, B, C)(C delegate(B) g, B delegate(A) f) {
	return v => g(f(v));
}

unittest {
	class SimpleObserver(T) : Observer!T {
		private int n=0;
		private int[] array = [3,4,5,6,7,8,9,10,11];
		override void onEach(T value) {
			assert(value == array[n++], "value=["~to!string(value)~"]");
		}
		
		override void onComplete() {
			
		}
		
		override void onError(Throwable t) {
			
		}
	}
	
	auto func = delegate(Observer!int observer) {
		foreach (number; 0..9) {
			observer.onEach(number);
		}
	};
	
	// Functor laws
	
	// fmap f . fmap g 
	Observable!int numberEmitter = new Observable!int(func);
	auto fmapF = numberEmitter.fmap((value) => value+1);
	auto fmapG = numberEmitter.fmap((value) => value+2);
	o(fmapG, fmapF)(numberEmitter).subscribe(new SimpleObserver!int);
	// fmap (f . g)
	numberEmitter.map(o((int value)=>value+2,(int value)=>value+1)).subscribe(new SimpleObserver!int);
}