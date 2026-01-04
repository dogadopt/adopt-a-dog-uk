import { useState, useRef, useEffect } from 'react';
import { Send, MessageSquare, Loader2 } from 'lucide-react';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useDogs } from '@/hooks/useDogs';
import { useRescues } from '@/hooks/useRescues';
import { getChatResponse, getStarterQuestions, type ChatMessage } from '@/services/chatService';
import { cn } from '@/lib/utils';

const Chat = () => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  
  // Fetch dogs and rescues data
  const { data: dogs = [], isLoading: dogsLoading } = useDogs();
  const { data: rescues = [], isLoading: rescuesLoading } = useRescues();
  
  const dataLoading = dogsLoading || rescuesLoading;
  const starterQuestions = getStarterQuestions({ dogs, rescues });
  
  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);
  
  // Initial greeting
  useEffect(() => {
    if (!dataLoading && messages.length === 0) {
      const greeting: ChatMessage = {
        id: '0',
        role: 'assistant',
        content: `Hello! 👋 I'm here to help you find information about dogs available for adoption and rescue organizations in the UK. What would you like to know?`,
        timestamp: new Date(),
      };
      setMessages([greeting]);
    }
  }, [dataLoading, messages.length]);
  
  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading || dataLoading) return;
    
    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue.trim(),
      timestamp: new Date(),
    };
    
    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);
    
    try {
      const response = await getChatResponse(inputValue.trim(), { dogs, rescues });
      
      const assistantMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response,
        timestamp: new Date(),
      };
      
      setMessages(prev => [...prev, assistantMessage]);
    } catch (error) {
      console.error('Error getting chat response:', error);
      
      const errorMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: "I'm sorry, I encountered an error processing your message. Please try again.",
        timestamp: new Date(),
      };
      
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };
  
  const handleStarterQuestion = (question: string) => {
    setInputValue(question);
  };
  
  // Format message content with basic markdown-like formatting
  const formatMessage = (content: string) => {
    // Split by lines and process
    const lines = content.split('\n');
    return lines.map((line, idx) => {
      // Bold text **text**
      const parts = line.split(/(\*\*[^*]+\*\*)/g);
      const formatted = parts.map((part, partIdx) => {
        if (part.startsWith('**') && part.endsWith('**')) {
          return <strong key={partIdx}>{part.slice(2, -2)}</strong>;
        }
        return part;
      });
      
      return (
        <span key={idx}>
          {formatted}
          {idx < lines.length - 1 && <br />}
        </span>
      );
    });
  };
  
  return (
    <div className="min-h-screen bg-background flex flex-col">
      <Header />
      
      <main className="flex-1 container mx-auto px-4 py-8 flex flex-col">
        <div className="mb-6">
          <h1 className="text-4xl font-display font-bold text-foreground mb-2">
            Chat with Us
          </h1>
          <p className="text-muted-foreground">
            Ask me anything about available dogs and rescue organizations
          </p>
        </div>
        
        <Card className="flex-1 flex flex-col min-h-0">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5" />
              Dog Adoption Assistant
            </CardTitle>
            <CardDescription>
              {dataLoading ? 'Loading data...' : `Currently tracking ${dogs.length} dogs and ${rescues.length} rescues`}
            </CardDescription>
          </CardHeader>
          
          <CardContent className="flex-1 flex flex-col min-h-0 pb-6">
            {/* Messages area */}
            <ScrollArea className="flex-1 pr-4 mb-4" ref={scrollAreaRef}>
              <div className="space-y-4">
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={cn(
                      'flex',
                      message.role === 'user' ? 'justify-end' : 'justify-start'
                    )}
                  >
                    <div
                      className={cn(
                        'max-w-[80%] rounded-lg px-4 py-3',
                        message.role === 'user'
                          ? 'bg-primary text-primary-foreground ml-12'
                          : 'bg-muted mr-12'
                      )}
                    >
                      <div className="text-sm whitespace-pre-wrap">
                        {formatMessage(message.content)}
                      </div>
                      <div
                        className={cn(
                          'text-xs mt-1',
                          message.role === 'user'
                            ? 'text-primary-foreground/70'
                            : 'text-muted-foreground'
                        )}
                      >
                        {message.timestamp.toLocaleTimeString([], { 
                          hour: '2-digit', 
                          minute: '2-digit' 
                        })}
                      </div>
                    </div>
                  </div>
                ))}
                
                {isLoading && (
                  <div className="flex justify-start">
                    <div className="bg-muted rounded-lg px-4 py-3 max-w-[80%]">
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Thinking...
                      </div>
                    </div>
                  </div>
                )}
                
                <div ref={messagesEndRef} />
              </div>
            </ScrollArea>
            
            {/* Starter questions */}
            {messages.length <= 1 && !isLoading && (
              <div className="mb-4">
                <p className="text-sm text-muted-foreground mb-2">Try asking:</p>
                <div className="flex flex-wrap gap-2">
                  {starterQuestions.map((question, idx) => (
                    <Button
                      key={idx}
                      variant="outline"
                      size="sm"
                      onClick={() => handleStarterQuestion(question)}
                      disabled={dataLoading}
                      className="text-xs"
                    >
                      {question}
                    </Button>
                  ))}
                </div>
              </div>
            )}
            
            {/* Input area */}
            <div className="flex gap-2">
              <Input
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder={dataLoading ? "Loading data..." : "Type your message..."}
                disabled={isLoading || dataLoading}
                className="flex-1"
              />
              <Button
                onClick={handleSendMessage}
                disabled={!inputValue.trim() || isLoading || dataLoading}
                size="icon"
              >
                {isLoading ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <Send className="w-4 h-4" />
                )}
              </Button>
            </div>
            
            {/* API status indicator */}
            {!import.meta.env.VITE_OPENAI_API_KEY && (
              <p className="text-xs text-muted-foreground mt-2 text-center">
                Running in fallback mode (OpenAI API key not configured)
              </p>
            )}
          </CardContent>
        </Card>
      </main>
      
      <Footer />
    </div>
  );
};

export default Chat;
