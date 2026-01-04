import type { Dog } from '@/types/dog';
import type { Rescue } from '@/hooks/useRescues';

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface ChatContext {
  dogs: Dog[];
  rescues: Rescue[];
}

/**
 * Build a context string from available dogs and rescues data
 */
function buildContext(context: ChatContext): string {
  const { dogs, rescues } = context;
  
  let contextStr = 'Available Dogs:\n';
  dogs.forEach(dog => {
    contextStr += `- ${dog.name}: ${dog.breed}, ${dog.computedAge || dog.age}, ${dog.size}, ${dog.gender}`;
    contextStr += `, Located at ${dog.rescue} in ${dog.location}`;
    if (dog.goodWithKids) contextStr += ', Good with kids';
    if (dog.goodWithDogs) contextStr += ', Good with dogs';
    if (dog.goodWithCats) contextStr += ', Good with cats';
    contextStr += `\n  Description: ${dog.description}\n`;
  });
  
  contextStr += '\nRescue Organizations:\n';
  rescues.forEach(rescue => {
    contextStr += `- ${rescue.name} (${rescue.type}) in ${rescue.region}`;
    if (rescue.website) contextStr += ` - ${rescue.website}`;
    contextStr += '\n';
  });
  
  return contextStr;
}

/**
 * Generate a response using OpenAI API
 */
async function generateOpenAIResponse(
  userMessage: string,
  context: ChatContext
): Promise<string> {
  const apiKey = import.meta.env.VITE_OPENAI_API_KEY;
  
  if (!apiKey) {
    throw new Error('OpenAI API key not configured');
  }
  
  const contextStr = buildContext(context);
  
  const systemPrompt = `You are a helpful assistant for a dog adoption website. 
You have access to information about available dogs and rescue organizations in the UK.
Use the following data to answer questions accurately and helpfully.
Be friendly, encouraging, and help users find their perfect dog match.

${contextStr}`;

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
      temperature: 0.7,
      max_tokens: 500,
    }),
  });
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.statusText}`);
  }
  
  const data = await response.json();
  return data.choices[0]?.message?.content || 'Sorry, I could not generate a response.';
}

/**
 * Generate a fallback response using pattern matching
 */
function generateFallbackResponse(
  userMessage: string,
  context: ChatContext
): string {
  const message = userMessage.toLowerCase();
  const { dogs, rescues } = context;
  
  // Pattern: What dogs are available / Show me dogs
  if (message.includes('what dogs') || message.includes('show') && message.includes('dog')) {
    if (dogs.length === 0) {
      return "I'm sorry, there are currently no dogs available for adoption.";
    }
    
    const dogList = dogs.slice(0, 5).map(dog => 
      `• **${dog.name}**: ${dog.breed}, ${dog.computedAge || dog.age}, ${dog.size} ${dog.gender.toLowerCase()} at ${dog.rescue}`
    ).join('\n');
    
    const more = dogs.length > 5 ? `\n\n...and ${dogs.length - 5} more dogs available!` : '';
    return `Here are some dogs available for adoption:\n\n${dogList}${more}`;
  }
  
  // Pattern: Dogs good with children/kids
  if ((message.includes('good with') || message.includes('friendly')) && (message.includes('kid') || message.includes('child'))) {
    const kidFriendly = dogs.filter(d => d.goodWithKids);
    
    if (kidFriendly.length === 0) {
      return "I don't have information about dogs that are specifically noted as good with children at the moment.";
    }
    
    const dogList = kidFriendly.slice(0, 5).map(dog => 
      `• **${dog.name}**: ${dog.breed}, ${dog.computedAge || dog.age} at ${dog.rescue}`
    ).join('\n');
    
    return `Here are some dogs that are good with children:\n\n${dogList}`;
  }
  
  // Pattern: Dogs good with other dogs
  if ((message.includes('good with') || message.includes('friendly')) && message.includes('dog') && !message.includes('what')) {
    const dogFriendly = dogs.filter(d => d.goodWithDogs);
    
    if (dogFriendly.length === 0) {
      return "I don't have information about dogs that are specifically noted as good with other dogs at the moment.";
    }
    
    const dogList = dogFriendly.slice(0, 5).map(dog => 
      `• **${dog.name}**: ${dog.breed}, ${dog.computedAge || dog.age} at ${dog.rescue}`
    ).join('\n');
    
    return `Here are some dogs that are good with other dogs:\n\n${dogList}`;
  }
  
  // Pattern: Dogs good with cats
  if ((message.includes('good with') || message.includes('friendly')) && message.includes('cat')) {
    const catFriendly = dogs.filter(d => d.goodWithCats);
    
    if (catFriendly.length === 0) {
      return "I don't have information about dogs that are specifically noted as good with cats at the moment.";
    }
    
    const dogList = catFriendly.slice(0, 5).map(dog => 
      `• **${dog.name}**: ${dog.breed}, ${dog.computedAge || dog.age} at ${dog.rescue}`
    ).join('\n');
    
    return `Here are some dogs that are good with cats:\n\n${dogList}`;
  }
  
  // Pattern: Specific breed
  if (message.includes('breed')) {
    const breeds = new Set(dogs.flatMap(d => d.breeds));
    return `We have dogs of various breeds available including: ${Array.from(breeds).slice(0, 10).join(', ')}. Would you like to know more about a specific breed?`;
  }
  
  // Pattern: Size preference
  if (message.includes('small') || message.includes('medium') || message.includes('large')) {
    let size: 'Small' | 'Medium' | 'Large' | null = null;
    if (message.includes('small')) size = 'Small';
    else if (message.includes('medium')) size = 'Medium';
    else if (message.includes('large')) size = 'Large';
    
    if (size) {
      const sizedDogs = dogs.filter(d => d.size === size);
      
      if (sizedDogs.length === 0) {
        return `I'm sorry, there are currently no ${size.toLowerCase()} dogs available.`;
      }
      
      const dogList = sizedDogs.slice(0, 5).map(dog => 
        `• **${dog.name}**: ${dog.breed}, ${dog.computedAge || dog.age} at ${dog.rescue}`
      ).join('\n');
      
      const more = sizedDogs.length > 5 ? `\n\n...and ${sizedDogs.length - 5} more ${size.toLowerCase()} dogs!` : '';
      return `Here are some ${size.toLowerCase()} dogs available:\n\n${dogList}${more}`;
    }
  }
  
  // Pattern: Age preference
  if (message.includes('puppy') || message.includes('puppies') || message.includes('young') || message.includes('senior') || message.includes('adult')) {
    let age: string | null = null;
    if (message.includes('puppy') || message.includes('puppies')) age = 'Puppy';
    else if (message.includes('young')) age = 'Young';
    else if (message.includes('senior')) age = 'Senior';
    else if (message.includes('adult')) age = 'Adult';
    
    if (age) {
      const agedDogs = dogs.filter(d => (d.computedAge || d.age) === age);
      
      if (agedDogs.length === 0) {
        return `I'm sorry, there are currently no ${age.toLowerCase()} dogs available.`;
      }
      
      const dogList = agedDogs.slice(0, 5).map(dog => 
        `• **${dog.name}**: ${dog.breed}, ${dog.size} at ${dog.rescue}`
      ).join('\n');
      
      return `Here are some ${age.toLowerCase()} dogs available:\n\n${dogList}`;
    }
  }
  
  // Pattern: Location/Region
  if (message.includes('wales') || message.includes('scotland') || message.includes('england') || message.includes('rescue') && message.includes('in')) {
    const regions = rescues.map(r => r.region);
    const uniqueRegions = Array.from(new Set(regions));
    
    return `We work with rescues across the UK in regions including: ${uniqueRegions.slice(0, 10).join(', ')}. You can browse all rescues on our Rescues page.`;
  }
  
  // Pattern: Tell me about [dog name]
  if ((message.includes('tell me about') || message.includes('about')) && dogs.length > 0) {
    // Try to find a dog by name
    const words = message.split(' ');
    for (const word of words) {
      const dog = dogs.find(d => d.name.toLowerCase() === word);
      if (dog) {
        let info = `**${dog.name}** is a ${dog.computedAge || dog.age} ${dog.size.toLowerCase()} ${dog.breed} (${dog.gender.toLowerCase()}) `;
        info += `available at ${dog.rescue} in ${dog.location}.\n\n`;
        info += `${dog.description}\n\n`;
        
        const traits = [];
        if (dog.goodWithKids) traits.push('good with kids');
        if (dog.goodWithDogs) traits.push('good with dogs');
        if (dog.goodWithCats) traits.push('good with cats');
        
        if (traits.length > 0) {
          info += `${dog.name} is ${traits.join(', ')}.`;
        }
        
        return info;
      }
    }
  }
  
  // Default response with helpful suggestions
  return `I can help you find information about available dogs and rescues! Here are some things you can ask me:

• "What dogs are available?"
• "Show me dogs good with children"
• "Do you have any small dogs?"
• "Tell me about puppies"
• "What rescues are in Wales?"

Feel free to ask me anything about our available dogs!`;
}

/**
 * Main function to get a chat response
 */
export async function getChatResponse(
  userMessage: string,
  context: ChatContext
): Promise<string> {
  try {
    // Try OpenAI first if API key is configured
    const apiKey = import.meta.env.VITE_OPENAI_API_KEY;
    if (apiKey) {
      return await generateOpenAIResponse(userMessage, context);
    }
  } catch (error) {
    console.warn('OpenAI API failed, falling back to pattern matching:', error);
  }
  
  // Fall back to pattern matching
  return generateFallbackResponse(userMessage, context);
}

/**
 * Generate example starter questions based on available data
 */
export function getStarterQuestions(context: ChatContext): string[] {
  const { dogs } = context;
  const questions = ['What dogs are available?'];
  
  if (dogs.some(d => d.goodWithKids)) {
    questions.push('Show me dogs good with children');
  }
  
  if (dogs.some(d => d.size === 'Small')) {
    questions.push('Do you have any small dogs?');
  }
  
  if (dogs.some(d => (d.computedAge || d.age) === 'Puppy')) {
    questions.push('Tell me about puppies');
  }
  
  questions.push('What rescues are available?');
  
  return questions;
}
