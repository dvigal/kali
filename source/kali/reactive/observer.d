module kali.reactive.observer;

interface Observer(T) {
	
	void onEach(T value);
	
	void onComplete();
	
	void onError(Throwable t);
	
}