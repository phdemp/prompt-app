const OpenAI = require('openai');
const config = require('../config/env');

const client = new OpenAI({ apiKey: config.openai.apiKey });

const SYSTEM_PROMPTS = {
  general:
    'You are an expert prompt engineer. Your task is to improve and optimize the given prompt to make it clearer, more specific, and more effective for AI models. Maintain the original intent while enhancing clarity, specificity, and structure. Return only the optimized prompt without explanation.',

  coding:
    'You are an expert prompt engineer specializing in coding and software development prompts. Optimize the given prompt to elicit better code solutions. Ensure it specifies language, context, constraints, and expected output format clearly. Return only the optimized prompt without explanation.',

  creative:
    'You are an expert prompt engineer specializing in creative writing prompts. Optimize the given prompt to inspire richer, more vivid, and more engaging creative content. Add sensory details, tone guidance, and narrative direction where appropriate. Return only the optimized prompt without explanation.',

  analysis:
    'You are an expert prompt engineer specializing in analytical and research prompts. Optimize the given prompt to elicit thorough, structured, and insightful analysis. Clarify scope, depth, and desired output format. Return only the optimized prompt without explanation.',

  instruction:
    'You are an expert prompt engineer specializing in instructional and task-based prompts. Optimize the given prompt to produce clear, step-by-step guidance. Ensure it specifies the audience, level of detail, and expected format. Return only the optimized prompt without explanation.',
};

const VALID_TYPES = Object.keys(SYSTEM_PROMPTS);

const optimizePrompt = async (rawPrompt, optimizationType = 'general') => {
  const type = VALID_TYPES.includes(optimizationType) ? optimizationType : 'general';

  const response = await client.chat.completions.create({
    model: 'gpt-4o',
    max_tokens: 1024,
    messages: [
      { role: 'system', content: SYSTEM_PROMPTS[type] },
      { role: 'user', content: rawPrompt },
    ],
  });

  const optimizedPrompt = response.choices[0].message.content || '';
  const tokensUsed = response.usage?.total_tokens || 0;

  return { optimizedPrompt, tokensUsed };
};

module.exports = { optimizePrompt, VALID_TYPES };
